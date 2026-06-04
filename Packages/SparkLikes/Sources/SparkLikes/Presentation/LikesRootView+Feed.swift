// Module: SparkLikes — Feed scroll layer + bottom actions.

import SparkDesignSystem
import SwiftUI

extension LikesRootView {
    @ViewBuilder
    var feedLayer: some View {
        switch viewModel.loadState {
        case .empty:
            emptyFeedView
        case .failure(let error):
            SparkRetryUnavailableView(
                title: String(
                    localized: "likes.error.title",
                    defaultValue: "无法加载",
                    comment: "Error title"
                ),
                description: error.displayText
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            loadedFeedView
        case .idle, .loading:
            Color.black
        }
    }

    var actionBar: some View {
        HStack(spacing: 20) {
            Button {
                Task { await viewModel.passCurrentCard() }
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.weight(.semibold))
                    .frame(width: 56, height: 56)
                    .background(.thickMaterial, in: Circle())
            }
            .accessibilityLabel(
                String(localized: "likes.pass.a11y", defaultValue: "跳过", comment: "Pass")
            )
            .disabled(viewModel.currentCard == nil || viewModel.isPerformingAction)

            if viewModel.preferences.intent == .friends {
                Button {
                    Task { await viewModel.friendRequestCurrentCard() }
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 52, height: 52)
                        .background(.thickMaterial, in: Circle())
                }
                .accessibilityLabel(
                    String(localized: "likes.friend.a11y", defaultValue: "加好友", comment: "Friend")
                )
                .disabled(viewModel.currentCard == nil || viewModel.isPerformingAction)
            }

            Button {
                Task { await viewModel.likeCurrentCard() }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2.weight(.semibold))
                    .frame(width: 64, height: 64)
                    .background(.pink.gradient, in: Circle())
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(
                String(localized: "likes.like.a11y", defaultValue: "喜欢", comment: "Like")
            )
            .disabled(viewModel.currentCard == nil || viewModel.isPerformingAction)
            .sensoryFeedback(.success, trigger: viewModel.pendingMatch != nil)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private var emptyFeedView: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "likes.empty.title",
                    defaultValue: "暂时没有更多推荐",
                    comment: "Empty feed"
                ),
                systemImage: "heart.slash"
            )
        } description: {
            Text(
                String(
                    localized: "likes.empty.subtitle",
                    defaultValue: "调整发现偏好或稍后再来",
                    comment: "Empty hint"
                )
            )
        } actions: {
            Button(
                String(
                    localized: "likes.empty.adjustPrefs",
                    defaultValue: "调整发现偏好",
                    comment: "Adjust preferences"
                )
            ) {
                showPreferences = true
            }
            if viewModel.inboundCount > 0 {
                Button(
                    String(
                        localized: "likes.empty.viewInbound",
                        defaultValue: "查看喜欢你的人",
                        comment: "View inbound"
                    )
                ) {
                    showInbound = true
                }
            }
        }
        .foregroundStyle(.white)
    }

    private var loadedFeedView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                    DiscoverCardView(
                        card: card,
                        isActive: scrollPosition == card.id || index == viewModel.currentIndex,
                        intent: viewModel.preferences.intent,
                        onOpenProfile: { showProfileSheet = true }
                    )
                    .containerRelativeFrame(.vertical)
                    .id(card.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollPosition)
        .scrollIndicators(.hidden)
        .scrollDisabled(isPhotoZoomed)
        .onPreferenceChange(DiscoverPhotoZoomedPreferenceKey.self) { isPhotoZoomed = $0 }
        .onChange(of: scrollPosition) { _, newID in
            isPhotoZoomed = false
            if let newID, let index = viewModel.cards.firstIndex(where: { $0.id == newID }) {
                viewModel.currentIndex = index
            }
            Task { await viewModel.loadMoreIfNeeded(currentCardID: newID) }
        }
        .onChange(of: viewModel.currentIndex) { _, index in
            guard index >= 0, index < viewModel.cards.count else { return }
            let id = viewModel.cards[index].id
            if scrollPosition != id {
                scrollPosition = id
            }
        }
        .onAppear {
            if scrollPosition == nil, let first = viewModel.cards.first {
                scrollPosition = first.id
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.bottom, 120)
            }
        }
    }
}
