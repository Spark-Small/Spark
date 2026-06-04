// Module: SparkLikes — 喜欢 tab root (vertical discover feed).

import SparkDesignSystem
import SwiftUI

public struct LikesRootView: View {
    @State var viewModel: LikesFeedViewModel
    @State var showPreferences = false
    @State var showReportSheet = false
    @State var showInbound = false
    @State var showProfileSheet = false
    @State var scrollPosition: String?
    @State var isPhotoZoomed = false

    @Binding var pendingInbound: Bool
    let onOpenMatchConversation: LikesOpenConversationHandler
    let onOpenSharedActivity: (@Sendable (String) -> Void)?

    public init(
        repository: any LikesFeedRepository,
        pendingInbound: Binding<Bool> = .constant(false),
        onOpenMatchConversation: @escaping LikesOpenConversationHandler,
        onOpenSharedActivity: (@Sendable (String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: LikesFeedViewModel(repository: repository))
        _pendingInbound = pendingInbound
        self.onOpenMatchConversation = onOpenMatchConversation
        self.onOpenSharedActivity = onOpenSharedActivity
    }

    init(
        viewModel: LikesFeedViewModel,
        pendingInbound: Binding<Bool> = .constant(false),
        onOpenMatchConversation: @escaping LikesOpenConversationHandler,
        onOpenSharedActivity: (@Sendable (String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        _pendingInbound = pendingInbound
        self.onOpenMatchConversation = onOpenMatchConversation
        self.onOpenSharedActivity = onOpenSharedActivity
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                feedLayer
                if viewModel.loadState == .loading || viewModel.loadState == .idle {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(.black)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .task {
                if viewModel.loadState == .idle {
                    await viewModel.load()
                }
            }
            .onChange(of: pendingInbound) { _, _ in
                consumePendingInboundIfNeeded()
            }
            .onAppear {
                consumePendingInboundIfNeeded()
                Task { await viewModel.refreshInboundIfLoaded() }
            }
            .sheet(isPresented: $viewModel.showOnboarding) {
                LikesOnboardingSheet {
                    viewModel.markOnboardingSeen()
                }
            }
            .sheet(isPresented: $showPreferences) {
                LikesPreferencesSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showInbound) {
                LikesInboundListView(viewModel: viewModel)
            }
            .sheet(isPresented: $showProfileSheet) {
                if let card = viewModel.currentCard {
                    DiscoverProfileSheet(
                        card: card,
                        onReport: { showReportSheet = true },
                        onOpenSharedActivity: onOpenSharedActivity
                    )
                }
            }
            .sheet(isPresented: $showReportSheet) {
                if let card = viewModel.currentCard {
                    LikesReportSheet(peerName: card.displayName) { reason, detail in
                        Task { await viewModel.reportAndBlockCurrentCard(reason: reason, detail: detail) }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showProfileGate) {
                LikesViewerProfileGateSheet(viewModel: viewModel)
            }
            .sheet(isPresented: matchSheetBinding) {
                if let name = viewModel.pendingMatchPeerName {
                    MatchSheetView(
                        peerName: name,
                        peerCard: viewModel.pendingMatchCard,
                        icebreakers: viewModel.icebreakersForPendingMatch,
                        onSendMessage: { message in
                            Task { await openMatchConversation(initialMessage: message) }
                        },
                        onDismiss: {
                            viewModel.dismissMatchWithoutMessage()
                        },
                        onOpenSharedActivity: onOpenSharedActivity
                    )
                }
            }
            .alert(
                String(localized: "likes.status.title", defaultValue: "提示", comment: "Status alert"),
                isPresented: statusAlertBinding
            ) {
                Button(String(localized: "action.ok", defaultValue: "好", comment: "OK")) {
                    viewModel.clearStatusMessage()
                }
            } message: {
                if let message = viewModel.statusMessage {
                    Text(message)
                }
            }
            .alert(
                String(
                    localized: "likes.direct.title",
                    defaultValue: "已有会话",
                    comment: "Direct message alert title"
                ),
                isPresented: directMessageAlertBinding
            ) {
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel"), role: .cancel) {
                    viewModel.clearDirectMessagePresentation()
                }
                Button(String(localized: "likes.match.message", defaultValue: "发消息", comment: "Open chat")) {
                    Task { await openPendingDirectMessage() }
                }
            } message: {
                if let pending = viewModel.pendingDirectMessage {
                    Text(directMessageBody(for: pending.peerName))
                }
            }
            .alert(
                String(
                    localized: "likes.pref.hint.title",
                    defaultValue: "推荐不多了",
                    comment: "Preferences hint title"
                ),
                isPresented: $viewModel.showPreferencesHint
            ) {
                Button(String(localized: "likes.pref.hint.action", defaultValue: "调整偏好", comment: "Adjust prefs")) {
                    showPreferences = true
                }
                Button(String(localized: "action.later", defaultValue: "稍后再说", comment: "Later"), role: .cancel) {}
            } message: {
                Text(
                    String(
                        localized: "likes.pref.hint.message",
                        defaultValue: "试试扩大发现范围",
                        comment: "Preferences hint message"
                    )
                )
            }
        }
    }
}

#Preview {
    LikesRootView(repository: MockLikesFeedRepository()) { _, _, _ in }
}

#Preview("Likes — empty") {
    LikesRootView(
        viewModel: LikesFeedViewModel(repository: EmptyLikesFeedRepository()),
        onOpenMatchConversation: { _, _, _ in }
    )
}

#Preview("Likes — dark") {
    LikesPreviewSupport.darkMode {
        LikesRootView(repository: MockLikesFeedRepository()) { _, _, _ in }
    }
}
