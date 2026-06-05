// Module: SparkLikes — Inbound likes inbox.

import SwiftUI

enum LikesInboundPresentation {
    case sheet
    case sidebar
}

struct LikesInboundListView: View {
    @Bindable var viewModel: LikesFeedViewModel
    var presentation: LikesInboundPresentation = .sheet
    var isItemBlurred: (InboundLikeItem) -> Bool = { _ in false }
    var onBlurredItemTap: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch presentation {
        case .sheet:
            NavigationStack {
                inboundBody
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                                dismiss()
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        case .sidebar:
            inboundBody
        }
    }

    private var inboundBody: some View {
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
                inboundGrid
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
        .onAppear {
            LikesTelemetry.inboundOpened(count: viewModel.inboundCount)
        }
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
