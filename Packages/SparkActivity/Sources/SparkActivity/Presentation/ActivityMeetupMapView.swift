// Module: SparkActivity — Inline meetup map (geocode location name via MapKit).

import MapKit
import SparkDesignSystem
import SwiftUI

/// Navigation payload for pushing the meetup full-screen map.
struct ActivityMeetupMapRoute: Hashable, Sendable {
    let activityTitle: String
    let locationName: String
}

struct ActivityMeetupMapView: View {
    let activityTitle: String
    let locationName: String

    @Environment(\.openURL) private var openURL
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var loadState: LoadState = .loading

    enum LoadState: Equatable {
        case loading
        case loaded
        case failure
    }

    var body: some View {
        VStack(spacing: 0) {
            switch loadState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "activity.map.loading.a11y",
                            defaultValue: "正在加载地图",
                            comment: "Map loading"
                        )
                    )
            case .failure:
                SparkRetryUnavailableView(
                    title: String(
                        localized: "activity.map.error.title",
                        defaultValue: "无法显示地图",
                        comment: "Map error"
                    ),
                    description: String(
                        localized: "activity.map.error.subtitle",
                        defaultValue: "请稍后在系统地图中查看地点",
                        comment: "Map error hint"
                    )
                ) {
                    Task { await geocodeLocation() }
                }
            case .loaded:
                Map(position: $cameraPosition) {
                    if let coordinate {
                        Marker(activityTitle, coordinate: coordinate)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
            }

            if let url = ActivityMapURL.mapsURL(locationName: locationName) {
                Button {
                    openURL(url)
                } label: {
                    Label(
                        String(
                            localized: "activity.map.openExternal",
                            defaultValue: "在地图 App 中打开",
                            comment: "Open in Maps app"
                        ),
                        systemImage: "arrow.up.forward.app"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.sparkPressable)
                .padding(SparkLayoutMetrics.standardHorizontalPadding)
                .sparkGlassSurface(Rectangle())
            }
        }
        .navigationTitle(locationName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await geocodeLocation()
        }
    }

    @MainActor
    private func geocodeLocation() async {
        loadState = .loading
        let trimmed = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            loadState = .failure
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                loadState = .failure
                return
            }
            let resolved = item.placemark.coordinate
            coordinate = resolved
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: resolved,
                    latitudinalMeters: 800,
                    longitudinalMeters: 800
                )
            )
            loadState = .loaded
        } catch {
            loadState = .failure
        }
    }
}

#Preview {
    NavigationStack {
        ActivityMeetupMapView(activityTitle: "周末徒步", locationName: "上海市静安区")
    }
}
