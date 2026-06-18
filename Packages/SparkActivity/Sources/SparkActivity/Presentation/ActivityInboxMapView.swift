// Module: SparkActivity — Inbox map: all filtered activities on one meetup-style map.

import MapKit
import SparkDesignSystem
import SwiftUI

struct ActivityInboxMapView: View {
    let activities: [ActivityItem]
    var presentation: ActivityMapPresentation = .itinerary
    var onOpenActivity: ((String) -> Void)?

    @State private var pins: [ActivityMapPin] = []
    @State private var loadState: LoadState = .loading
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedPinID: String?
    @State private var presentedPinID: String?

    private enum LoadState: Equatable {
        case loading
        case loaded
        case empty
        case failure
    }

    struct ActivityMapPin: Identifiable, Sendable {
        let id: String
        let title: String
        let locationName: String
        let coordinate: CLLocationCoordinate2D
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "activity.inboxMap.loading.a11y",
                            defaultValue: "正在加载活动地图",
                            comment: "Inbox map loading"
                        )
                    )
            case .empty:
                ContentUnavailableView(
                    presentation.emptyTitle,
                    systemImage: "mappin.slash",
                    description: Text(presentation.emptySubtitle)
                )
            case .failure:
                SparkRetryUnavailableView(
                    title: String(
                        localized: "activity.map.error.title",
                        defaultValue: "无法显示地图",
                        comment: "Map error"
                    ),
                    description: String(
                        localized: "activity.inboxMap.error.subtitle",
                        defaultValue: "请稍后重试",
                        comment: "Inbox map error hint"
                    )
                ) {
                    Task { await resolvePins() }
                }
            case .loaded:
                Map(position: $cameraPosition, selection: $selectedPinID) {
                    ForEach(pins) { pin in
                        Marker(pin.title, coordinate: pin.coordinate)
                            .tag(pin.id)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
            }
        }
        .onChange(of: selectedPinID) { _, pinID in
            presentedPinID = pinID
        }
        .sheet(
            isPresented: Binding(
                get: { presentedPinID != nil },
                set: { isPresented in
                    if !isPresented {
                        presentedPinID = nil
                        selectedPinID = nil
                    }
                }
            )
        ) {
            if let pinID = presentedPinID, let pin = pins.first(where: { $0.id == pinID }) {
                NavigationStack {
                    ActivityMeetupMapView(activityTitle: pin.title, locationName: pin.locationName)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(String(localized: "action.close", defaultValue: "关闭", comment: "Close")) {
                                    presentedPinID = nil
                                    selectedPinID = nil
                                }
                            }
                            if let onOpenActivity {
                                ToolbarItem(placement: .primaryAction) {
                                    Button(
                                        String(
                                            localized: "activity.inboxMap.openDetail",
                                            defaultValue: "查看活动",
                                            comment: "Open activity from map pin"
                                        )
                                    ) {
                                        onOpenActivity(pin.id)
                                        presentedPinID = nil
                                        selectedPinID = nil
                                    }
                                }
                            }
                        }
                }
            }
        }
        .task(id: activities.map(\.id)) {
            await resolvePins()
        }
    }

    @MainActor
    private func resolvePins() async {
        loadState = .loading
        selectedPinID = nil
        presentedPinID = nil
        let mappable = activities.filter {
            !$0.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !mappable.isEmpty else {
            pins = []
            loadState = .empty
            return
        }

        var resolved: [ActivityMapPin] = []
        var coordinateCache: [String: CLLocationCoordinate2D] = [:]

        for activity in mappable {
            let locationKey = activity.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
            let coordinate: CLLocationCoordinate2D?
            if let cached = coordinateCache[locationKey] {
                coordinate = cached
            } else {
                coordinate = await geocode(locationName: locationKey)
                if let coordinate {
                    coordinateCache[locationKey] = coordinate
                }
            }
            guard let coordinate else { continue }
            resolved.append(
                ActivityMapPin(
                    id: activity.id,
                    title: activity.title,
                    locationName: locationKey,
                    coordinate: coordinate
                )
            )
        }

        guard !resolved.isEmpty else {
            pins = []
            loadState = .failure
            return
        }

        pins = resolved.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        cameraPosition = .region(regionFitting(pins.map(\.coordinate)))
        loadState = .loaded
    }

    private func geocode(locationName: String) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = locationName
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            return nil
        }
    }

    private func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion()
        }
        guard coordinates.count > 1 else {
            return MKCoordinateRegion(
                center: first,
                latitudinalMeters: 800,
                longitudinalMeters: 800
            )
        }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = max((maxLat - minLat) * 1.4, 0.02)
        let lonDelta = max((maxLon - minLon) * 1.4, 0.02)
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

#Preview {
    NavigationStack {
        ActivityInboxMapView(
            activities: [
                ActivityItem(
                    id: "preview-hike",
                    title: "周末徒步",
                    summary: "",
                    category: "户外",
                    locationName: "上海市静安区"
                ),
                ActivityItem(
                    id: "preview-coffee",
                    title: "咖啡聊天",
                    summary: "",
                    category: "社交",
                    locationName: "北京市朝阳区"
                )
            ]
        )
    }
}
