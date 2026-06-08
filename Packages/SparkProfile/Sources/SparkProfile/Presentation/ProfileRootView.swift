// Module: SparkProfile — Profile tab root layout sections.

import SparkCore
import SparkDesignSystem
import SparkNotifications
import SparkPayments
import SparkSearch
import SparkTrust
import SwiftUI

public struct ProfileRootView: View {
    public var viewModel: ProfileViewModel
    public let profileCoordinator: ProfileCoordinator
    public let onSelectSearchResult: (SearchResultItem) -> Void
    public let onSignOut: () -> Void
    public let onDeleteAccount: () async -> Void
    public let onOpenPaywall: () -> Void
    public let onOpenPersonMessages: ((String) -> Void)?

    @State private var showVerificationWizard = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var showNotificationSettings = false
    @State private var searchQuery = ""
    @ScaledMetric(relativeTo: .body) private var profileAvatarSize = SparkLayoutMetrics.tabPersonAvatarSize

    public init(
        viewModel: ProfileViewModel,
        profileCoordinator: ProfileCoordinator,
        onSelectSearchResult: @escaping (SearchResultItem) -> Void,
        onSignOut: @escaping () -> Void,
        onDeleteAccount: @escaping () async -> Void,
        onOpenPaywall: @escaping () -> Void,
        onOpenPersonMessages: ((String) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.profileCoordinator = profileCoordinator
        self.onSelectSearchResult = onSelectSearchResult
        self.onSignOut = onSignOut
        self.onDeleteAccount = onDeleteAccount
        self.onOpenPaywall = onOpenPaywall
        self.onOpenPersonMessages = onOpenPersonMessages
    }

    public var body: some View {
        NavigationStack {
            SparkScreenContainer(
                navigationTitle: "",
                titleDisplayMode: .inline,
                embedding: .none
            ) {
                profileContent
                    .accessibilityElement(children: .contain)
            }
            .task {
                if viewModel.loadState == .idle {
                    await viewModel.load()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SearchRootView(
                            coordinator: profileCoordinator.makeSearchCoordinator(),
                            initialQuery: searchQuery,
                            onSelectResult: onSelectSearchResult,
                            onOpenPersonMessages: onOpenPersonMessages
                        )
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel(
                        String(localized: "community.search.a11y", defaultValue: "搜索", comment: "Search")
                    )
                }
            }
            .sparkPhoneStyleNavigationBar()
            .sheet(isPresented: $showVerificationWizard) {
                TrustVerificationWizardView(
                    viewModel: profileCoordinator.makeVerificationViewModel {
                        Task { await viewModel.load() }
                    }
                )
            }
            .confirmationDialog(
                String(
                    localized: "auth.signOut.confirm.title",
                    defaultValue: "退出登录？",
                    comment: "Sign out confirm"
                ),
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    String(localized: "auth.signOut", defaultValue: "退出登录", comment: "Sign out"),
                    role: .destructive
                ) {
                    onSignOut()
                }
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel"), role: .cancel) {}
            }
            .confirmationDialog(
                String(
                    localized: "auth.deleteAccount.confirm.title",
                    defaultValue: "注销账号？",
                    comment: "Delete account confirm title"
                ),
                isPresented: $showDeleteAccountConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    String(
                        localized: "auth.deleteAccount.confirm.action",
                        defaultValue: "永久注销",
                        comment: "Delete account confirm"
                    ),
                    role: .destructive
                ) {
                    Task { await onDeleteAccount() }
                }
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel"), role: .cancel) {}
            } message: {
                Text(
                    String(
                        localized: "auth.deleteAccount.confirm.message",
                        defaultValue: "将删除你的账号与服务器上的个人数据，此操作不可撤销。",
                        comment: "Delete account confirm message"
                    )
                )
            }
            .sheet(isPresented: $showNotificationSettings) {
                NavigationStack {
                    NotificationPreferencesView()
                        .navigationTitle(
                            String(
                                localized: "notifications.settings.title",
                                defaultValue: "通知设置",
                                comment: "Notification settings"
                            )
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(String(localized: "common.done", defaultValue: "完成", comment: "Done")) {
                                    showNotificationSettings = false
                                }
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var profileContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sparkLoadingAccessibilityLabel(
                    String(
                        localized: "profile.loading.a11y",
                        defaultValue: "正在加载资料",
                        comment: "Profile loading"
                    )
                )
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(
                    localized: "profile.error.title",
                    defaultValue: "无法加载资料",
                    comment: "Profile error"
                ),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            List {
                if let summary = viewModel.summary {
                    profileIdentityRow(profile: summary)
                        .sparkFlatTabListRow()
                    if SparkFeatureFlags.isPremiumPaywallEnabled {
                        premiumRow
                            .sparkFlatTabListRow()
                    }
                    trustRow(profile: summary)
                        .sparkFlatTabListRow()
                }
                accountSettingsRow
                    .sparkFlatTabListRow()
                notificationSettingsRow
                    .sparkFlatTabListRow()
                privacyPolicyRow
                    .sparkFlatTabListRow()
                termsOfServiceRow
                    .sparkFlatTabListRow()
                icpRow
                    .sparkFlatTabListRow()
                signOutRow
                    .sparkFlatTabListRow()
                deleteAccountRow
                    .sparkFlatTabListRow()
            }
            .sparkFlatTabListStyle()
        }
    }

    private func profileIdentityRow(profile: ProfileSummary) -> some View {
        ProfileFlatRow(
            title: displayNameText,
            preview: trustPreviewLine(profile: profile),
            leading: { profileAvatar }
        )
    }

    private var premiumRow: some View {
        Button {
            onOpenPaywall()
        } label: {
            ProfileFlatRow(
                title: String(localized: "paywall.cta", defaultValue: "Premium", comment: "Premium CTA"),
                preview: String(
                    localized: "profile.premium.preview",
                    defaultValue: "解锁更多功能",
                    comment: "Premium row preview"
                ),
                leading: {
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
                }
            )
        }
        .buttonStyle(.sparkPressable)
    }

    @ViewBuilder
    private func trustRow(profile: ProfileSummary) -> some View {
        let title = String(
            localized: "profile.section.trust",
            defaultValue: "信任认证",
            comment: "Trust section"
        )
        let preview = trustActionPreview(profile: profile)
        let leading = {
            Image(systemName: "checkmark.shield")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
        }

        if profile.trustProfile.nextMVPPendingLevel != nil {
            Button {
                showVerificationWizard = true
            } label: {
                ProfileFlatRow(title: title, preview: preview, leading: leading)
            }
            .buttonStyle(.sparkPressable)
        } else {
            ProfileFlatRow(title: title, preview: preview, leading: leading)
        }
    }

    private var accountSettingsRow: some View {
        NavigationLink {
            AccountSettingsView(
                onOpenNotificationSettings: { showNotificationSettings = true },
                onOpenPaywall: onOpenPaywall
            )
        } label: {
            ProfileFlatRow(
                title: String(
                    localized: "profile.accountSettings.title",
                    defaultValue: "账号设置",
                    comment: "Account settings"
                ),
                preview: String(
                    localized: "profile.accountSettings.preview",
                    defaultValue: "隐私、安全与偏好",
                    comment: "Account settings preview"
                ),
                leading: {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
                }
            )
        }
    }

    private var notificationSettingsRow: some View {
        Button {
            showNotificationSettings = true
        } label: {
            ProfileFlatRow(
                title: String(
                    localized: "notifications.settings.title",
                    defaultValue: "通知设置",
                    comment: "Notification settings"
                ),
                preview: String(
                    localized: "profile.notifications.preview",
                    defaultValue: "推送与提醒",
                    comment: "Notifications preview"
                ),
                leading: {
                    Image(systemName: "bell")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
                }
            )
        }
        .buttonStyle(.sparkPressable)
    }

    private var privacyPolicyRow: some View {
        Link(destination: SparkLegalLinks.privacyPolicyURL) {
            ProfileFlatRow(
                title: String(
                    localized: "legal.privacyPolicy",
                    defaultValue: "隐私政策",
                    comment: "Privacy policy link"
                ),
                preview: String(
                    localized: "profile.legal.preview",
                    defaultValue: "查看法律文档",
                    comment: "Legal row preview"
                ),
                leading: {
                    Image(systemName: "hand.raised")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
                }
            )
        }
        .buttonStyle(.sparkPressable)
    }

    private var termsOfServiceRow: some View {
        Link(destination: SparkLegalLinks.termsOfServiceURL) {
            ProfileFlatRow(
                title: String(
                    localized: "legal.termsOfService",
                    defaultValue: "用户协议",
                    comment: "Terms of service link"
                ),
                preview: String(
                    localized: "profile.legal.preview",
                    defaultValue: "查看法律文档",
                    comment: "Legal row preview"
                ),
                leading: {
                    Image(systemName: "doc.text")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
                }
            )
        }
        .buttonStyle(.sparkPressable)
    }

    private var icpRow: some View {
        ProfileFlatRow(
            title: String(
                localized: "legal.icp.label",
                defaultValue: "ICP 备案号",
                comment: "ICP record label"
            ),
            preview: SparkLegalLinks.icpRecordNumber,
            leading: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
            }
        )
    }

    private var signOutRow: some View {
        Button(role: .destructive) {
            showSignOutConfirmation = true
        } label: {
            ProfileFlatRow(
                title: String(localized: "auth.signOut", defaultValue: "退出登录", comment: "Sign out"),
                preview: String(
                    localized: "profile.signOut.preview",
                    defaultValue: "退出当前账号",
                    comment: "Sign out preview"
                ),
                titleForegroundStyle: .red,
                leading: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
                }
            )
        }
        .buttonStyle(.sparkPressable)
    }

    private var deleteAccountRow: some View {
        Button(role: .destructive) {
            showDeleteAccountConfirmation = true
        } label: {
            ProfileFlatRow(
                title: String(
                    localized: "auth.deleteAccount",
                    defaultValue: "注销账号",
                    comment: "Delete account"
                ),
                preview: String(
                    localized: "profile.deleteAccount.preview",
                    defaultValue: "永久删除账号与数据",
                    comment: "Delete account preview"
                ),
                titleForegroundStyle: .red,
                leading: {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
                }
            )
        }
        .buttonStyle(.sparkPressable)
        .accessibilityHint(
            String(
                localized: "auth.deleteAccount.hint",
                defaultValue: "永久删除账号与服务器数据",
                comment: "Delete account hint"
            )
        )
    }

    private func trustPreviewLine(profile: ProfileSummary) -> String {
        let format = String(
            localized: "profile.trust.score.preview.format",
            defaultValue: "信任分 %lld",
            comment: "Trust score preview; %lld is score"
        )
        return String(format: format, locale: .current, profile.trustProfile.totalScore)
    }

    private func trustActionPreview(profile: ProfileSummary) -> String {
        if profile.trustProfile.nextMVPPendingLevel != nil {
            return String(
                localized: "profile.verify.cta",
                defaultValue: "完成信任认证",
                comment: "Verify CTA"
            )
        }
        return String(
            localized: "profile.trust.complete",
            defaultValue: "已完成基础认证",
            comment: "Trust complete"
        )
    }

    private var displayNameText: String {
        String(localized: "profile.displayName.placeholder", defaultValue: "Spark 用户", comment: "Profile name")
    }

    @ViewBuilder
    private var profileAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: profileAvatarSize))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel(
                String(localized: "profile.avatar.a11y", defaultValue: "头像", comment: "Profile avatar")
            )
    }
}

// MARK: - Flat row (Messages ConversationRow pattern)

private struct ProfileFlatRow<Leading: View, Trailing: View>: View {
    let title: String
    let preview: String
    var titleForegroundStyle: Color = .primary
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        preview: String,
        titleForegroundStyle: Color = .primary,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.preview = preview
        self.titleForegroundStyle = titleForegroundStyle
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                leading()
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(titleForegroundStyle)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        trailing()
                    }
                    Text(preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.inboxRowVerticalPadding)
            .frame(
                minHeight: SparkLayoutMetrics.inboxConversationRowMinHeight,
                alignment: .center
            )
            .accessibilityElement(children: .combine)

            Divider()
        }
    }
}

#Preview {
    profilePreviewRoot()
}

#Preview("Profile — dark") {
    SparkPreviewSupport.darkMode {
        profilePreviewRoot()
    }
}

#Preview("Profile — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        profilePreviewRoot()
    }
}

@MainActor
private func profilePreviewRoot() -> some View {
    ProfileRootView(
        viewModel: ProfileViewModel(trustRepository: MockTrustRepository()),
        profileCoordinator: ProfileCoordinator(
            trustRepository: MockTrustRepository(),
            searchRepository: MockSearchRepository(),
            userContextRepository: MockUserContextRepository()
        ),
        onSelectSearchResult: { _ in },
        onSignOut: {},
        onDeleteAccount: {},
        onOpenPaywall: {}
    )
}
