//
//  ProfileHomeHeaderView.swift
//  坐标系
//
//  「我的」资料头：首行左头像 + 右昵称/简介（点按进编辑资料）；下一整行折叠粉丝。
//  昵称↔简介 = `cell()` 主副文距；头↔粉丝行 = headerToFooterSpacing。
//

import CoordinateModels
import SwiftUI

struct ProfileHomeHeaderView: View {
    @Environment(AppModel.self) private var app
    @Environment(MembershipStore.self) private var membership
    @Environment(PhotoVerificationStore.self) private var photoVerification

    @State private var showsSocialGraphSheet = false

    private var photoVerified: Bool {
        photoVerification.isVerified(for: app.user)
    }

    private var bio: String {
        app.user.bio.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var socialGraphInitialTab: ProfileSocialGraphSheetTab {
        let fans = ProfileSocialStats.fansCount(for: app.user.name, app: app)
        return fans > 0 ? .fans : .following
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformAccountHeaderMetrics.headerToFooterSpacing) {
            identityEditLink
            ProfileHomeFansCollapsedRow {
                showsSocialGraphSheet = true
            }
        }
        .discoverBrowseContentInset()
        .sheet(isPresented: $showsSocialGraphSheet) {
            ProfileSocialGraphSheet(initialTab: socialGraphInitialTab)
        }
    }

    /// 头像 + 昵称/简介整块进编辑资料（Settings 账户行同职）。
    private var identityEditLink: some View {
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
            identityRow
        }
        .buttonStyle(.plain)
        .accessibilityLabel(identityAccessibilityLabel)
        .accessibilityHint(ProfileDashboardCopy.editProfileCTA)
    }

    /// 昵称↔简介：`nameToBioSpacing` = `cell()` 主副文距（非 subtitleCell=0、非整行 margin）。
    private var identityRow: some View {
        HStack(alignment: .center, spacing: PlatformAccountHeaderMetrics.imageToTextPadding) {
            PlatformListAvatarView(
                name: app.user.name,
                photo: app.user.localAvatarImage,
                side: PlatformAccountHeaderMetrics.avatarSide
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PlatformAccountHeaderMetrics.nameToBioSpacing) {
                Text(app.user.name)
                    .font(PlatformListTypography.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)

                if !bio.isEmpty {
                    Text(bio)
                        .font(PlatformListTypography.secondary)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    private var identityAccessibilityLabel: String {
        [
            app.user.name,
            photoVerified ? "认证已通过" : "认证未认证",
            membership.isEntitled ? "会员已开通" : "会员未开通"
        ].joined(separator: "，")
    }
}
