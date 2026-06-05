// Module: SparkLikes — Two-column inbound grid layout.

import SwiftUI

extension LikesInboundListView {
    var inboundGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.sortedInboundItems) { item in
                    InboundLikeCell(
                        item: item,
                        isBlurred: isItemBlurred(item) || !item.isVisible,
                        onLikeBack: {
                            Task { await viewModel.likeInboundUser(item.userID) }
                        },
                        onUnlock: onBlurredItemTap
                    )
                    .onAppear {
                        Task {
                            await viewModel.loadMoreInboundIfNeeded(currentItemID: item.id)
                        }
                    }
                }
            }
            .padding()
            if viewModel.isLoadingMoreInbound {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
}
