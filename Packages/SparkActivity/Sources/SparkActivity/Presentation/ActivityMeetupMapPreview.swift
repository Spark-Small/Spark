// Module: SparkActivity — Compact meetup map preview (detail when/where block).

import MapKit
import SparkDesignSystem
import SwiftUI

struct ActivityMeetupMapPreview: View {
    let activityTitle: String
    let locationName: String
    let onOpenMap: () -> Void

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var loadState: LoadState = .idle

    private enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failure
    }

    var body: some View {
        Button(action: onOpenMap) {
            Group {
                switch loadState {
                case .idle, .loading:
                    RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous)
                        .fill(.quaternary)
                        .overlay {
                            ProgressView()
                                .sparkLoadingAccessibilityLabel(
                                    String(
                                        localized: "activity.map.preview.loading.a11y",
                                        defaultValue: "正在加载地图预览",
                                        comment: "Map preview loading"
                                    )
                                )
                        }
                case .failure:
                    RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous)
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                case .loaded:
                    Map(position: $cameraPosition, interactionModes: []) {
                        if let coordinate {
                            Marker(activityTitle, coordinate: coordinate)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.sparkPressable)
        .accessibilityLabel(locationName)
        .accessibilityHint(
            String(
                localized: "activity.detail.map.hint",
                defaultValue: "查看碰头地点地图",
                comment: "Map hint"
            )
        )
        .task {
            await geocodeLocationIfNeeded()
        }
    }

    @MainActor
    private func geocodeLocationIfNeeded() async {
        guard loadState == .idle else { return }
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
