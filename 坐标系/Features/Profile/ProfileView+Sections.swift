//
//  ProfileView+Sections.swift
//  坐标系
//
//  「我的」根 List：身份单 cell（头像账户头+四列）→ 服务 → 我的内容。
//  形象认证入口在个人资料；我的内容：活动 / 陪玩 / 发帖 / 俱乐部。
//

import SwiftData
import SwiftUI
import CoordinateModels

extension ProfileView {
    // MARK: - Sections

    @ViewBuilder
    var lifecycleTipSection: some View {
        if let tip = lifecycleTips.first {
            Section {
                ProductLifecycleTipSectionContent(
                    tip: tip,
                    onDismiss: { lifecycle.dismissTip(tip.id) },
                    onOpenSettings: tip.id == "privacy"
                        ? { navigation.path.append(ProfileRoute.privacy) }
                        : nil
                )
            } header: {
                Label(tip.title, systemImage: tip.systemImage)
                    .platformContentSymbolStyle()
            }
        }
    }

    /// 身份：单 List cell（官方路径）— 账户头 + 四列，块距用 subtitleCell 行 margin。
    var identitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: PlatformAccountHeaderMetrics.headerToFooterSpacing) {
                // Settings「Apple ID」：整行账户头 + 系统 disclosure（层级进入个人资料）。
                NavigationLink {
                    EditProfileSheet(
                        user: Binding(
                            get: { app.user },
                            set: { app.updateProfile($0) }
                        ),
                        embedsOwnNavigationChrome: false
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                } label: {
                    PlatformAccountHeaderLabel(
                        title: app.user.name,
                        subtitle: identitySubtitle,
                        showsPhotoVerified: photoVerified,
                        showsMemberVIP: membership.isEntitled
                    ) {
                        PlatformListAvatarView(
                            name: app.user.name,
                            photo: app.user.localAvatarImage,
                            side: PlatformAccountHeaderMetrics.avatarSide
                        )
                    }
                }
                .accessibilityHint("打开个人资料")
                .accessibilityLabel(identityAccessibilityLabel)

                ProfileSocialStatsRow(
                    likesCount: ProfileSocialStats.likesReceived(for: app.user.name, community: community),
                    mutualCount: ProfileSocialStats.mutualCount(
                        for: app.user.name,
                        app: app,
                        messages: messages
                    ),
                    followingCount: ProfileSocialStats.followingCount(for: app.user.name, app: app),
                    fansCount: ProfileSocialStats.fansCount(for: app.user.name, app: app),
                    onLikesTap: { showLikesReceivedInfo = true },
                    onMutualTap: { navigation.path.append(ProfileRoute.socialGraph(.mutual)) },
                    onFollowingTap: { navigation.path.append(ProfileRoute.socialGraph(.following)) },
                    onFansTap: { navigation.path.append(ProfileRoute.socialGraph(.fans)) }
                )
            }
            .accessibilityElement(children: .contain)
        }
    }

    /// 生活照片墙：身份区下、服务区上（Ins 式三列，选完即写本机）。
    var lifePhotosSection: some View {
        Section {
            ProfileLifePhotosGrid()
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        } header: {
            Text(ProfileGalleryCopy.sectionTitle)
        }
    }

    /// 会员 · 钱包（与系统「账户服务」同形态，无广告印象轨）。
    var servicesSection: some View {
        Section {
            ProfileFormGatedRow(
                title: membership.isEntitled
                    ? ProfileDashboardCopy.membershipCenter
                    : ProfileDashboardCopy.membershipOpen,
                systemImage: membership.isEntitled ? "checkmark.seal.fill" : "crown.fill"
            ) {
                openCommerce { navigation.path.append(ProfileRoute.membership) }
            }

            ProfileFormGatedRow(
                title: ProfileDashboardCopy.walletEntry,
                systemImage: "creditcard.fill"
            ) {
                openCommerce { navigation.path.append(ProfileRoute.wallet) }
            }
        } header: {
            Text(ProfileDashboardCopy.servicesSectionTitle)
        }
    }

    /// Form：我的活动 / 我的陪玩 / 我的发帖 / 我的俱乐部。
    var librarySection: some View {
        Section {
            NavigationLink(value: ProfileRoute.activitiesLibrary) {
                Label(ProfileDashboardCopy.activitiesTitle, systemImage: "calendar")
                    .platformContentSymbolStyle()
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
                    Label(ProfileDashboardCopy.myCompanionEntry, systemImage: "ticket.fill")
                        .platformContentSymbolStyle()
                }
            }

            NavigationLink(value: ProfileRoute.myPosts) {
                LabeledContent {
                    // 草稿优先（待完成），否则已发布数——对齐陪玩「待处理优先」。
                    let drafts = community.postDrafts.count
                    let posts = ProfileSocialStats.postCount(for: app.user.name, community: community)
                    let count = drafts > 0 ? drafts : posts
                    if count > 0 {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.myPostsEntry, systemImage: "square.and.pencil")
                        .platformContentSymbolStyle()
                }
            }

            NavigationLink(value: ProfileRoute.myClubs) {
                LabeledContent {
                    let count = buddies.membershipClubs.count
                    if count > 0 {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.myClubsEntry, systemImage: "person.3.fill")
                        .platformContentSymbolStyle()
                }
            }
        } header: {
            Text(ProfileDashboardCopy.librarySectionTitle)
        }
    }

    // MARK: - Derived

    /// 账户头副文：@账号 · MBTI · 星座（有则拼，短、好扫）。
    var identitySubtitle: String? {
        var parts: [String] = []
        let handle = app.user.handle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !handle.isEmpty {
            parts.append(handle.hasPrefix("@") ? handle : "@\(handle)")
        }
        if let mbti = app.user.mbti {
            parts.append(mbti.rawValue)
        }
        if let zodiac = app.user.displayZodiac {
            parts.append(zodiac.rawValue)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var identityAccessibilityLabel: String {
        var parts = [app.user.name]
        if let identitySubtitle { parts.append(identitySubtitle) }
        parts.append(
            [
                photoVerified ? "认证已通过" : "认证未认证",
                membership.isEntitled ? "会员已开通" : "会员未开通"
            ].joined(separator: " · ")
        )
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
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
