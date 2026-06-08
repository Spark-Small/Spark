// Module: SparkProfile — Unified user context sheet (W9).

import SparkCore
import SparkDesignSystem
import SwiftUI

public struct UserContextPresentation: Identifiable, Sendable, Equatable {
    public let userID: String

    public var id: String { userID }

    public init(userID: String) {
        self.userID = userID
    }
}

@MainActor
@Observable
public final class UserContextViewModel {
    enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded(UserContext)
        case failure(String)
    }

    private(set) var loadState: LoadState = .idle
    private let fetchContext: any FetchUserContextUseCaseProtocol
    private let userID: String

    init(userID: String, fetchContext: any FetchUserContextUseCaseProtocol) {
        self.userID = userID
        self.fetchContext = fetchContext
    }

    func load() async {
        loadState = .loading
        do {
            let context = try await fetchContext(userID: userID)
            loadState = .loaded(context)
            IntegrationTelemetry.profileCardOpened(userID: userID)
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}

public struct UserContextSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: UserContextViewModel
    let onSendMessage: (() -> Void)?
    let onInviteToActivity: (() -> Void)?

    public init(
        userID: String,
        fetchContext: any FetchUserContextUseCaseProtocol,
        onSendMessage: (() -> Void)? = nil,
        onInviteToActivity: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: UserContextViewModel(userID: userID, fetchContext: fetchContext))
        self.onSendMessage = onSendMessage
        self.onInviteToActivity = onInviteToActivity
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .task { await viewModel.load() }
                case .failure(let message):
                    SparkRetryUnavailableView(
                        title: String(
                            localized: "profile.context.error.title",
                            defaultValue: "无法加载资料",
                            comment: "User context error"
                        ),
                        description: message
                    ) {
                        Task { await viewModel.load() }
                    }
                case .loaded(let context):
                    SparkUnifiedIdentityContent(model: context.unifiedIdentityModel()) {
                        primaryActions(for: context)
                    }
                }
            }
            .navigationTitle(
                String(localized: "profile.context.title", defaultValue: "资料", comment: "User context title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.close", defaultValue: "关闭", comment: "Close")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func primaryActions(for context: UserContext) -> some View {
        VStack(spacing: 12) {
            if let onSendMessage {
                Button(action: onSendMessage) {
                    Text(
                        String(localized: "profile.context.sendMessage", defaultValue: "发消息", comment: "Send message")
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            if let onInviteToActivity {
                Button(action: onInviteToActivity) {
                    Text(
                        String(
                            localized: "profile.context.inviteActivity",
                            defaultValue: "邀请参加活动",
                            comment: "Invite to activity"
                        )
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            if onSendMessage == nil, onInviteToActivity == nil {
                Text(context.relationshipStatus ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    UserContextSheet(
        userID: "user_1",
        fetchContext: FetchUserContextUseCase(repository: MockUserContextRepository())
    )
}
