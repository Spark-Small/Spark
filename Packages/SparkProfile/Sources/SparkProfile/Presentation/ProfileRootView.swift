// Module: SparkProfile — Nexus「我的」tab root.

import SparkDesignSystem
import SparkPayments
import SparkSearch
import SparkTrust
import SwiftUI

public struct ProfileRootView: View {
    public var viewModel: ProfileViewModel
    public let trustRepository: any TrustRepository
    public let searchRepository: any SearchRepository
    public let onSelectSearchResult: (SearchResultItem) -> Void
    public let onSignOut: () -> Void
    public let onOpenPaywall: () -> Void

    @State private var showVerificationWizard = false
    @State private var searchQuery = ""

    public init(
        viewModel: ProfileViewModel,
        trustRepository: any TrustRepository,
        searchRepository: any SearchRepository,
        onSelectSearchResult: @escaping (SearchResultItem) -> Void,
        onSignOut: @escaping () -> Void,
        onOpenPaywall: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.trustRepository = trustRepository
        self.searchRepository = searchRepository
        self.onSelectSearchResult = onSelectSearchResult
        self.onSignOut = onSignOut
        self.onOpenPaywall = onOpenPaywall
    }

    public var body: some View {
        NavigationStack {
            SparkScreenContainer(
                navigationTitle: String(localized: "screen.profile", defaultValue: "我的", comment: "Profile screen"),
                embedding: .none
            ) {
                profileContent
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
                TrustVerificationWizardView(repository: trustRepository) {
                    Task { await viewModel.load() }
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
                            repository: searchRepository,
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

                Section {
                    Button(
                        String(localized: "auth.signOut", defaultValue: "退出登录", comment: "Sign out"),
                        role: .destructive
                    ) {
                        onSignOut()
                    }
                }
            }
            .sparkScreenListStyle()
        }
    }
}

#Preview {
    ProfileRootView(
        viewModel: ProfileViewModel(trustRepository: MockTrustRepository()),
        trustRepository: MockTrustRepository(),
        searchRepository: MockSearchRepository(),
        onSelectSearchResult: { _ in },
        onSignOut: {},
        onOpenPaywall: {}
    )
}
