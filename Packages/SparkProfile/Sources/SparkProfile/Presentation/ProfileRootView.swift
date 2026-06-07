// Module: SparkProfile — Profile tab root.

import SparkCore
import SparkDesignSystem
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

    @State private var showVerificationWizard = false
    @State private var showDeleteAccountConfirmation = false
    @State private var searchQuery = ""

    public init(
        viewModel: ProfileViewModel,
        profileCoordinator: ProfileCoordinator,
        onSelectSearchResult: @escaping (SearchResultItem) -> Void,
        onSignOut: @escaping () -> Void,
        onDeleteAccount: @escaping () async -> Void,
        onOpenPaywall: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.profileCoordinator = profileCoordinator
        self.onSelectSearchResult = onSelectSearchResult
        self.onSignOut = onSignOut
        self.onDeleteAccount = onDeleteAccount
        self.onOpenPaywall = onOpenPaywall
    }

    public var body: some View {
        NavigationStack {
            SparkScreenContainer(
                navigationTitle: String(localized: "screen.profile", defaultValue: "我的", comment: "Profile screen"),
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
                    if SparkFeatureFlags.isPremiumPaywallEnabled {
                        Button(
                            String(localized: "paywall.cta", defaultValue: "Premium", comment: "Premium CTA")
                        ) {
                            onOpenPaywall()
                        }
                    }
                }
            }
            .sheet(isPresented: $showVerificationWizard) {
                TrustVerificationWizardView(
                    viewModel: profileCoordinator.makeVerificationViewModel {
                        Task { await viewModel.load() }
                    }
                )
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
                if let profile = viewModel.profile {
                    Section {
                        TrustScoreRingView(profile: profile)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                        if profile.nextMVPPendingLevel != nil {
                            Button(
                                String(
                                    localized: "profile.verify.cta",
                                    defaultValue: "完成信任认证",
                                    comment: "Verify CTA"
                                )
                            ) {
                                showVerificationWizard = true
                            }
                        }
                    }
                }

                Section(
                    String(
                        localized: "profile.section.discover",
                        defaultValue: "发现",
                        comment: "Discover section"
                    )
                ) {
                    NavigationLink {
                        SearchRootView(
                            coordinator: profileCoordinator.makeSearchCoordinator(),
                            initialQuery: searchQuery,
                            onSelectResult: onSelectSearchResult
                        )
                    } label: {
                        Label(
                            String(localized: "screen.search", defaultValue: "搜索", comment: "Search"),
                            systemImage: "magnifyingglass"
                        )
                    }
                }

                Section(
                    String(
                        localized: "profile.section.legal",
                        defaultValue: "法律信息",
                        comment: "Legal section"
                    )
                ) {
                    Link(
                        String(
                            localized: "legal.privacyPolicy",
                            defaultValue: "隐私政策",
                            comment: "Privacy policy link"
                        ),
                        destination: SparkLegalLinks.privacyPolicyURL
                    )
                    Link(
                        String(
                            localized: "legal.termsOfService",
                            defaultValue: "用户协议",
                            comment: "Terms of service link"
                        ),
                        destination: SparkLegalLinks.termsOfServiceURL
                    )
                }

                Section(
                    String(
                        localized: "profile.section.about",
                        defaultValue: "关于",
                        comment: "About section"
                    )
                ) {
                    LabeledContent(
                        String(
                            localized: "legal.icp.label",
                            defaultValue: "ICP 备案号",
                            comment: "ICP record label"
                        ),
                        value: SparkLegalLinks.icpRecordNumber
                    )
                }

                Section {
                    Button(
                        String(localized: "auth.signOut", defaultValue: "退出登录", comment: "Sign out"),
                        role: .destructive
                    ) {
                        onSignOut()
                    }
                    Button(
                        String(
                            localized: "auth.deleteAccount",
                            defaultValue: "注销账号",
                            comment: "Delete account"
                        ),
                        role: .destructive
                    ) {
                        showDeleteAccountConfirmation = true
                    }
                    .accessibilityHint(
                        String(
                            localized: "auth.deleteAccount.hint",
                            defaultValue: "永久删除账号与服务器数据",
                            comment: "Delete account hint"
                        )
                    )
                }
            }
            .sparkScreenListStyle()
        }
    }
}

#Preview {
    ProfileRootView(
        viewModel: ProfileViewModel(trustRepository: MockTrustRepository()),
        profileCoordinator: ProfileCoordinator(
            trustRepository: MockTrustRepository(),
            searchRepository: MockSearchRepository()
        ),
        onSelectSearchResult: { _ in },
        onSignOut: {},
        onDeleteAccount: {},
        onOpenPaywall: {}
    )
}
