//
//  ProfileView+Sections.swift
//  坐标系
//
//  「我的」根 List：身份 → 待办（条件）→ 服务 → 我的内容。
//  最近浏览归活动/搭子标题菜单；会员入口在服务区列表行。
//

import SwiftData
import SwiftUI
import CoordinateModels

extension ProfileView {
    var profilePromoKind: ActivityNextUpPresentation.BrowsePromoHeader? {
        ActivityNextUpPresentation.BrowsePromoHeader.resolve(
            hasSeenWelcomeGuide: app.welcomeGuide.hasSeenGuide,
            from: activities
        )
    }

    // MARK: - Sections

    @ViewBuilder
    var lifecycleTipSection: some View {
        if let tip = lifecycleTips.first {
            Section {
                ProductLifecycleTipSectionContent(
                    tip: tip,
                    onDismiss: { lifecycle.dismissTip(tip.id) },
                    onOpenSettings: tip.id == "privacy" ? { showSettingsFromTip = true } : nil
                )
            } header: {
                Label(tip.title, systemImage: tip.systemImage)
                    .platformContentSymbolStyle()
            }
        }
    }

    var identitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Button(action: openIdentity) {
                    HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                        ProfileAvatarView(user: app.user)

                        VStack(alignment: .leading) {
                            Text(app.user.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(app.user.handle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("打开个人资料编辑")
                .accessibilityLabel(identityAccessibilityLabel)

                Button {
                    navigation.path.append(ProfileRoute.trust)
                } label: {
                    TrustCredentialBadgeStrip(
                        photoVerified: photoVerified,
                        isMember: membership.isEntitled
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(ProfileDashboardCopy.trustBadgeAccessibilityHint)

                ProfileSocialStatsRow(
                    postCount: ProfileSocialStats.postCount(for: app.user.name, community: community),
                    followingCount: ProfileSocialStats.followingCount(for: app.user.name, app: app),
                    fansCount: ProfileSocialStats.fansCount(for: app.user.name, app: app)
                )
            }
            .listRowSeparator(.hidden)
        }
    }

    /// 有下一场时才出现；订单待办用「服务 · 我的订单」角标，避免双入口。
    @ViewBuilder
    var attentionSection: some View {
        if case .nextUp(let summary) = profilePromoKind {
            Section {
                nextUpFormRow(summary)
                    .id(summary.promoIdentity(calendarSyncRevision: activities.calendarSyncRevision))
            } header: {
                Text(ProfileDashboardCopy.attentionSectionTitle)
            }
        }
    }

    /// 会员 · 钱包 · 订单。
    var servicesSection: some View {
        Section {
            ProfileMembershipAdContentView(
                isActive: membership.isEntitled,
                onTap: {
                    openCommerce { navigation.path.append(ProfileRoute.membership) }
                }
            )

            ProfileFormGatedRow(
                title: ProfileDashboardCopy.walletEntry,
                systemImage: "creditcard.fill"
            ) {
                openCommerce { navigation.path.append(ProfileRoute.wallet) }
            }

            NavigationLink(value: ProfileRoute.orders(nil)) {
                LabeledContent {
                    let pending = orderAttentionCount
                    if pending > 0 {
                        Text("\(pending)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.ordersTitle, systemImage: "list.clipboard.fill")
                        .platformContentSymbolStyle()
                }
            }
        } header: {
            Text(ProfileDashboardCopy.servicesSectionTitle)
        } footer: {
            if orderAttentionCount > 0 {
                Text(ProfileDashboardCopy.ordersPendingBookingFooter)
            }
        }
    }

    /// ≤4 行：活动与行程 / 陪玩预约 / 俱乐部 / 广场内容。
    var librarySection: some View {
        Section {
            NavigationLink(value: ProfileRoute.activitiesLibrary) {
                LabeledContent {
                    let invites = buddies.inviteRecords.filter { $0.status == .pending }.count
                    if invites > 0 {
                        Text("\(invites)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.activitiesLibraryTitle, systemImage: "calendar")
                        .platformContentSymbolStyle()
                }
            }

            NavigationLink(value: ProfileRoute.bookingCredentials) {
                LabeledContent {
                    let attention = buddies.pendingBookingAttentionCount
                    let count = buddies.bookingCredentialCount
                    if attention > 0 {
                        Text("\(attention)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } else if count > 0 {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.bookingCredentials, systemImage: "ticket.fill")
                        .platformContentSymbolStyle()
                }
            }

            NavigationLink(value: ProfileRoute.myClubs) {
                LabeledContent {
                    let count = buddies.joinedCircles.count
                    if count > 0 {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.myClubsTitle, systemImage: "person.3.fill")
                        .platformContentSymbolStyle()
                }
            }

            NavigationLink(value: ProfileRoute.communityLibrary) {
                Label(ProfileDashboardCopy.communityLibraryTitle, systemImage: "square.grid.2x2.fill")
                    .platformContentSymbolStyle()
            }
        } header: {
            Text(ProfileDashboardCopy.librarySectionTitle)
        } footer: {
            if buddies.actionableBookingCount > 0 {
                Text(
                    BuddyBrowseCopy.MyBookings.statusFooter(
                        count: buddies.actionableBookingCount,
                        needsAttention: buddies.pendingBookingAttentionCount
                    )
                )
            }
        }
    }

    /// 「下一场」Form 行。
    func nextUpFormRow(_ summary: ActivityNextUpPresentation.Summary) -> some View {
        Button {
            switch summary.primaryAction {
            case .openJourney:
                openJourney(summary.activity)
            case .navigate:
                navigateActivity = summary.activity
            }
        } label: {
            LabeledContent {
                Text(summary.pendingHint ?? summary.headline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } label: {
                Label(summary.activity.title, systemImage: "flag.checkered")
                    .platformContentSymbolStyle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(summary.promoAccessibilitySummary)
        .accessibilityHint(summary.trailingActionTitle)
    }

    // MARK: - Derived

    var identityAccessibilityLabel: String {
        var parts = [app.user.name, app.user.handle]
        parts.append(
            [
                photoVerified ? "认证已通过" : "认证未认证",
                membership.isEntitled ? "会员已开通" : "会员未开通"
            ].joined(separator: " · ")
        )
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
    }

    var orderAttentionCount: Int {
        let counts = ProfileOrderShortcutCounts.compute(
            activityOrders: ActivityPaymentStore.allOrders(),
            bookingRecords: buddies.bookingRecords
        )
        return counts.pendingPayment + counts.pendingConfirm
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
