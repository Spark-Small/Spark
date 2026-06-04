// Module: SparkLikes — Inbound likes inbox.

import SwiftUI

struct LikesInboundListView: View {
    @Bindable var viewModel: LikesFeedViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.inboundItems.isEmpty {
                    ContentUnavailableView(
                        String(
                            localized: "likes.inbound.empty.title",
                            defaultValue: "暂无新的喜欢",
                            comment: "Inbound empty"
                        ),
                        systemImage: "heart",
                        description: Text(
                            String(
                                localized: "likes.inbound.empty.subtitle",
                                defaultValue: "继续浏览推荐，让更多人看到你",
                                comment: "Inbound empty hint"
                            )
                        )
                    )
                } else {
                    List {
                        ForEach(viewModel.inboundItems) { item in
                            inboundRow(item)
                                .onAppear {
                                    Task {
                                        await viewModel.loadMoreInboundIfNeeded(currentItemID: item.id)
                                    }
                                }
                        }
                        if viewModel.isLoadingMoreInbound {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .navigationTitle(
                String(
                    localized: "likes.inbound.title",
                    defaultValue: "喜欢你的人",
                    comment: "Inbound title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                LikesTelemetry.inboundOpened(count: viewModel.inboundCount)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func inboundRow(_ item: InboundLikeItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.card.displayName)
                    .font(.headline)
                if !item.card.bio.isEmpty {
                    Text(item.card.bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button {
                Task { await viewModel.likeInboundUser(item.userID) }
            } label: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                String(
                    localized: "likes.inbound.likeBack.a11y",
                    defaultValue: "喜欢回去",
                    comment: "Like back"
                )
            )
            .disabled(viewModel.isPerformingAction)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LikesInboundListView(viewModel: LikesFeedViewModel(repository: MockLikesFeedRepository()))
}

#Preview("Inbound — accessibility XL") {
    LikesPreviewSupport.accessibilityXL {
        LikesInboundListView(viewModel: LikesFeedViewModel(repository: MockLikesFeedRepository()))
    }
}
