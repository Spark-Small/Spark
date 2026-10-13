//
//  ProfileView+Sections.swift
//  坐标系
//
//  「我的」社交主页块编排：资料头 → 四档内容（Scroll）。
//

import SwiftUI

extension ProfileView {
    // MARK: - Home blocks

    @ViewBuilder
    var lifecycleTipBanner: some View {
        if let tip = lifecycleTips.first {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Label(tip.title, systemImage: tip.systemImage)
                    .font(PlatformListTypography.secondaryEmphasized)
                    .platformContentSymbolStyle()
                ProductLifecycleTipSectionContent(
                    tip: tip,
                    onDismiss: { lifecycle.dismissTip(tip.id) },
                    onOpenSettings: tip.id == "privacy"
                        ? { navigation.path.append(ProfileRoute.privacy) }
                        : nil
                )
            }
            .discoverBrowseContentInset()
        }
    }

    var profileHomeHero: some View {
        ProfileHomeHeaderView()
    }

    var profileHomeContent: some View {
        ProfileHomeContentTabs(
            selection: $homeContentTab,
            activityZoomNamespace: activityZoomNamespace
        )
    }

    var lifecycleTips: [ProductLifecycleTip] {
        guard lifecycle.daysSinceInstall < 7 else { return [] }
        let hasOrders = !ActivityPaymentStore.allOrders().isEmpty
            || !buddies.bookingRecords.isEmpty
        return lifecycle.activeTips(
            isGuest: false,
            profileComplete: ProfileCompletion.ratio(for: app.user) >= 0.8,
            hasOrders: hasOrders
        )
    }
}
