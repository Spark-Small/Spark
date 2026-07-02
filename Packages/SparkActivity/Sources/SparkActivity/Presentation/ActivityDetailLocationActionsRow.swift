// Module: SparkActivity — Location actions after venue (navigate · copy · map).

import SparkDesignSystem
import SwiftUI

struct ActivityDetailLocationActionsRow: View {
    let activity: ActivityDetail
    let onOpenDirections: () -> Void
    let onViewMap: () -> Void
    let onCopyLocation: () -> Void

    private var showsDirections: Bool {
        activity.lifecycleStatus == .scheduled && activity.rsvpStatus.hasGroupChatAccess
    }

    private var showsViewMap: Bool {
        activity.lifecycleStatus == .scheduled && !activity.rsvpStatus.hasGroupChatAccess
    }

    private var showsOpenInMaps: Bool {
        activity.lifecycleStatus != .scheduled
    }

    var body: some View {
        HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
            if showsDirections {
                actionButton(
                    title: String(
                        localized: "activity.detail.navigate",
                        defaultValue: "导航",
                        comment: "Navigate to venue"
                    ),
                    systemImage: "location.fill",
                    isProminent: true,
                    action: onOpenDirections
                )
                .accessibilityHint(
                    String(
                        localized: "activity.detail.navigate.hint",
                        defaultValue: "在地图 App 中开始导航至集合地点",
                        comment: "Navigate hint"
                    )
                )
            } else if showsViewMap {
                actionButton(
                    title: String(
                        localized: "activity.detail.viewMap",
                        defaultValue: "查看地图",
                        comment: "View map before RSVP"
                    ),
                    systemImage: "map",
                    isProminent: true,
                    action: onViewMap
                )
                .accessibilityHint(
                    String(
                        localized: "activity.detail.viewMap.hint",
                        defaultValue: "查看碰头区域地图，报名后可开启精确导航",
                        comment: "View map hint"
                    )
                )
            } else if showsOpenInMaps {
                actionButton(
                    title: String(
                        localized: "activity.map.openExternal",
                        defaultValue: "在地图 App 中打开",
                        comment: "Open in Maps app"
                    ),
                    systemImage: "arrow.up.forward.app",
                    isProminent: false,
                    action: onOpenDirections
                )
            }

            if activity.lifecycleStatus == .scheduled {
                actionButton(
                    title: String(
                        localized: "activity.detail.copyLocation",
                        defaultValue: "复制地点",
                        comment: "Copy location"
                    ),
                    systemImage: "doc.on.doc",
                    isProminent: false,
                    action: onCopyLocation
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        systemImage: String,
        isProminent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        if isProminent {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview("Going") {
    if let activity = MockActivityCatalog.detail(id: "act_1") {
        ActivityDetailLocationActionsRow(
            activity: activity,
            onOpenDirections: {},
            onViewMap: {},
            onCopyLocation: {}
        )
        .padding()
    }
}

#Preview("Invited") {
    if let activity = MockActivityCatalog.detail(id: "act_2") {
        ActivityDetailLocationActionsRow(
            activity: activity,
            onOpenDirections: {},
            onViewMap: {},
            onCopyLocation: {}
        )
        .padding()
    }
}
