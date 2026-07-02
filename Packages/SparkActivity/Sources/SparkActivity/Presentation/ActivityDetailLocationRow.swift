// Module: SparkActivity — Location row with ride + external map menu.

import SparkDesignSystem
import SwiftUI

struct ActivityDetailLocationRow: View {
    let activity: ActivityDetail
    let onOpenInAppMap: () -> Void
    let onOpenExternalMap: (ActivityMapProvider) -> Void
    let onOpenRideHailing: () -> Void

    private var trimmedLocation: String {
        activity.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var privacyNote: String? {
        activity.rsvpStatus.hasGroupChatAccess
            ? nil
            : String(
                localized: "activity.detail.location.privacy",
                defaultValue: "报名后可查看精确集合地点",
                comment: "Location privacy note"
            )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: onOpenRideHailing) {
                Image(systemName: "car.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.sparkPressable)
            .accessibilityLabel(
                String(
                    localized: "activity.detail.ride.a11y",
                    defaultValue: "打车导航",
                    comment: "Ride hailing a11y"
                )
            )
            .accessibilityHint(
                String(
                    localized: "activity.detail.ride.hint",
                    defaultValue: "打开地图 App 导航至集合地点",
                    comment: "Ride hailing hint"
                )
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(trimmedLocation)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let privacyNote {
                    Text(privacyNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            mapProviderMenu
        }
        .accessibilityElement(children: .contain)
    }

    private var mapProviderMenu: some View {
        Menu {
            Button {
                onOpenInAppMap()
            } label: {
                Label(
                    String(
                        localized: "activity.detail.map.inApp",
                        defaultValue: "在 Spark 中查看",
                        comment: "In-app map"
                    ),
                    systemImage: "map"
                )
            }

            ForEach(ActivityMapProvider.allCases) { provider in
                Button {
                    onOpenExternalMap(provider)
                } label: {
                    Text(provider.localizedLabel)
                }
            }
        } label: {
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel(
            String(
                localized: "activity.detail.map.menu.a11y",
                defaultValue: "打开位置",
                comment: "Map provider menu a11y"
            )
        )
    }
}

#Preview {
    if let activity = MockActivityCatalog.detail(id: "act_1") {
        ActivityDetailLocationRow(
            activity: activity,
            onOpenInAppMap: {},
            onOpenExternalMap: { _ in },
            onOpenRideHailing: {}
        )
        .padding()
    }
}
