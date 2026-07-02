// Module: SparkActivity — Activity tab home segments: 发现 / 地图.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    var activityHomeSegmentToolbarPicker: some View {
        SparkToolbarSegmentedPicker(
            options: Array(ActivityHomeSegment.allCases),
            selection: $selectedHomeSegment,
            title: \.localizedTitle,
            accessibilityLabel: String(
                localized: "activity.home.segment.a11y",
                defaultValue: "活动主页",
                comment: "Activity home segment picker"
            )
        )
    }

    @ViewBuilder
    var homeSegmentRootContent: some View {
        SparkPreservedSegmentStack(
            selection: selectedHomeSegment,
            segments: Array(ActivityHomeSegment.allCases)
        ) { segment in
            switch segment {
            case .discover:
                discoverSegmentBody
            case .map:
                mapSegmentContent
            }
        }
    }

    @ViewBuilder
    private var discoverSegmentBody: some View {
        Group {
            if coordinator.hasBrowseCatalog, let browseViewModel {
                ActivityBrowseContent(
                    viewModel: browseViewModel,
                    coordinator: coordinator,
                    isItemLocked: isItemLocked,
                    onLockedItemTap: onLockedItemTap,
                    isAuthenticated: isAuthenticated,
                    pendingBrowseJoinActivityID: $pendingBrowseJoinActivityID,
                    joinSheetItem: $discoverJoinSheetItem,
                    onSelectActivity: { activityID in
                        openActivity(activityID)
                    },
                    onOpenHostProfile: { hostID, displayName in
                        openHostProfile(hostID: hostID, displayName: displayName)
                    },
                    onSignInRequiredForBrowseJoin: onSignInRequiredForBrowseJoin,
                    onRSVPCompleted: { detail in
                        await onRSVPCompleted?(detail)
                        await reloadVisibleCatalogs()
                    }
                )
                .sparkTabTopAccessory(isEnabled: tabChrome.isTopAccessoryEnabled) {
                    ActivityBrowseFilterBar(viewModel: browseViewModel)
                }
                .modifier(DiscoverLegacyCreateCTAModifier(
                    isVisible: showsLegacyDiscoverCreateCTA,
                    isGuest: !isAuthenticated,
                    onCreate: { pendingCreateActivityDraft = CreateActivityDraft() }
                ))
                .task { await browseViewModel.loadIfNeeded() }
            } else {
                ContentUnavailableView(
                    String(
                        localized: "activity.browse.unavailable.title",
                        defaultValue: "发现暂不可用",
                        comment: "Browse unavailable"
                    ),
                    systemImage: "map",
                    description: Text(
                        String(
                            localized: "activity.browse.unavailable.subtitle",
                            defaultValue: "请稍后再试。",
                            comment: "Browse unavailable hint"
                        )
                    )
                )
                .sparkContentUnavailableCanvas()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    var mapSegmentContent: some View {
        if isAuthenticated {
            inboxMapContent
                .task {
                    if viewModel.loadState == .idle {
                        await viewModel.load()
                    }
                }
        } else {
            guestMapSignInPrompt
        }
    }

    private var guestMapSignInPrompt: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "activity.guest.map.title",
                    defaultValue: "登录查看活动地图",
                    comment: "Guest map title"
                ),
                systemImage: "map"
            )
        } description: {
            Text(
                String(
                    localized: "activity.guest.map.subtitle",
                    defaultValue: "你的报名与主办活动会显示在地图上。",
                    comment: "Guest map subtitle"
                )
            )
        } actions: {
            Button(action: { onSignInRequired?() }) {
                Text(
                    String(
                        localized: "auth.login.signIn",
                        defaultValue: "登录",
                        comment: "Sign in"
                    )
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .sparkContentUnavailableCanvas()
    }

    func ensureBrowseViewModelIfNeeded() {
        guard coordinator.hasBrowseCatalog, browseViewModel == nil else { return }
        browseViewModel = coordinator.makeBrowseViewModel()
        syncTabChrome()
    }

    var showsLegacyDiscoverCreateCTA: Bool {
        if #available(iOS 26.1, *) {
            return false
        }
        return isActivityTabSelected
            && isAtActivityHomeRoot
            && !showMyActivities
            && selectedHomeSegment == .discover
            && coordinator.hasBrowseCatalog
    }
}

// MARK: - Legacy create CTA

private struct DiscoverLegacyCreateCTAModifier: ViewModifier {
    let isVisible: Bool
    let isGuest: Bool
    let onCreate: () -> Void

    func body(content: Content) -> some View {
        if #unavailable(iOS 26.1) {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                if isVisible {
                    ActivityDiscoverLegacyCreateCTA(isGuest: isGuest, action: onCreate)
                }
            }
        } else {
            content
        }
    }
}
