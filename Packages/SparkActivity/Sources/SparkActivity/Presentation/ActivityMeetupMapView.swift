// Module: SparkActivity — Meetup location map (L3 push from activity detail).

import MapKit
import SparkDesignSystem
import SwiftUI

/// Navigation payload for pushing the meetup map from activity detail.
struct ActivityMeetupMapRoute: Hashable, Sendable {
    let activityTitle: String
    let locationName: String
    /// When true, primary action opens turn-by-turn directions (going / host).
    let showsDirections: Bool

    init(activityTitle: String, locationName: String, showsDirections: Bool = false) {
        self.activityTitle = activityTitle
        self.locationName = locationName
        self.showsDirections = showsDirections
    }
}

struct ActivityMeetupMapView: View {
    let activityTitle: String
    let locationName: String
    let showsDirections: Bool

    @Environment(\.openURL) private var openURL
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var loadState: LoadState = .loading

    enum LoadState: Equatable {
        case loading
        case loaded
        case failure
    }

    init(activityTitle: String, locationName: String, showsDirections: Bool = false) {
        self.activityTitle = activityTitle
        self.locationName = locationName
        self.showsDirections = showsDirections
    }

    init(route: ActivityMeetupMapRoute) {
        self.init(
            activityTitle: route.activityTitle,
            locationName: route.locationName,
            showsDirections: route.showsDirections
        )
    }

    var body: some View {
        SparkScreenContainer(
            navigationTitle: String(
                localized: "activity.map.title",
                defaultValue: "碰头地点",
                comment: "Meetup map screen title"
            ),
            titleDisplayMode: .inline,
            embedding: .none
        ) {
            Group {
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
                    .sparkContentUnavailableCanvas()
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomChrome
        }
        .sparkPhoneStyleNavigationBar()
        .task {
            await geocodeLocation()
        }
    }

    private var bottomChrome: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
            locationSummary

            HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                if showsDirections, let url = ActivityMapURL.directionsURL(locationName: locationName) {
                    primaryActionButton(
                        title: String(
                            localized: "activity.detail.navigate",
                            defaultValue: "导航",
                            comment: "Navigate to venue"
                        ),
                        systemImage: "location.fill"
                    ) {
                        openURL(url)
                    }
                    .accessibilityHint(
                        String(
                            localized: "activity.detail.navigate.hint",
                            defaultValue: "在地图 App 中开始导航至集合地点",
                            comment: "Navigate hint"
                        )
                    )
                } else if let url = ActivityMapURL.mapsURL(locationName: locationName) {
                    primaryActionButton(
                        title: String(
                            localized: "activity.map.openExternal",
                            defaultValue: "在地图 App 中打开",
                            comment: "Open in Maps app"
                        ),
                        systemImage: "arrow.up.forward.app"
                    ) {
                        openURL(url)
                    }
                }

                secondaryActionButton(
                    title: String(
                        localized: "activity.detail.copyLocation",
                        defaultValue: "复制地点",
                        comment: "Copy location"
                    ),
                    systemImage: "doc.on.doc",
                    action: copyLocation
                )
                .accessibilityHint(
                    String(
                        localized: "activity.detail.copyLocation.hint",
                        defaultValue: "复制集合地点，方便发给同行好友",
                        comment: "Copy location hint"
                    )
                )
            }
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private var locationSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activityTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Label {
                Text(locationName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.secondary)
            }
            .labelStyle(.titleAndIcon)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func primaryActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func secondaryActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
    }

    private func copyLocation() {
        let trimmed = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ActivityPasteboard.copy(trimmed)
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

// MARK: - Previews

#Preview("Meetup map") {
    NavigationStack {
        ActivityMeetupMapView(activityTitle: "周末徒步", locationName: "上海市静安区")
    }
}

#Preview("Meetup map — directions") {
    NavigationStack {
        ActivityMeetupMapView(
            activityTitle: "周末徒步",
            locationName: "上海市静安区",
            showsDirections: true
        )
    }
}

#Preview("Meetup map — dark") {
    SparkPreviewSupport.darkMode {
        NavigationStack {
            ActivityMeetupMapView(activityTitle: "周末徒步", locationName: "上海市静安区")
        }
    }
}

#Preview("Meetup map — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        NavigationStack {
            ActivityMeetupMapView(activityTitle: "周末徒步", locationName: "上海市静安区")
        }
    }
}
