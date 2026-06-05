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
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.cardsBrowsedThisSession)

            if viewModel.preferences.intent == .match {
                Button {
                    Task { await handleSparkTap() }
                } label: {
                    Image(systemName: "bolt.fill")
                        .font(.title2.weight(.semibold))
                        .frame(width: 60, height: 60)
                        .background(.yellow.gradient, in: Circle())
                        .foregroundStyle(.black)
                }
                .accessibilityLabel(
                    String(localized: "likes.spark.a11y", defaultValue: "心动", comment: "Spark")
                )
                .disabled(viewModel.currentCard == nil || viewModel.isPerformingAction)
                .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.sparkBurstToken)
            } else {
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

    func handleSparkTap() async {
        if viewModel.dailyStats.sparkChargesRemaining <= 0 {
            onSparkPaywall()
            return
        }
        await viewModel.sparkCurrentCard()
    }

    private var emptyFeedView: some View {
        ContentUnavailableView {
            Label(
                emptyFeedTitle,
                systemImage: viewModel.isDailyPoolExhausted ? "sun.horizon" : "heart.slash"
            )
        } description: {
            Text(emptyFeedSubtitle)
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

    private var emptyFeedTitle: String {
        if viewModel.isDailyPoolExhausted {
            return String(
                localized: "likes.empty.daily.title",
                defaultValue: "今日已看完",
                comment: "Daily pool exhausted title"
            )
        }
        return String(
            localized: "likes.empty.title",
            defaultValue: "暂时没有更多推荐",
            comment: "Empty feed"
        )
    }

    private var emptyFeedSubtitle: String {
        if viewModel.isDailyPoolExhausted {
            return String(
                localized: "likes.empty.daily.subtitle",
                defaultValue: "明天再来，或去活动认识新朋友",
                comment: "Daily pool exhausted subtitle"
            )
        }
        return String(
            localized: "likes.empty.subtitle",
            defaultValue: "调整发现偏好或稍后再来",
            comment: "Empty hint"
        )
    }

    private var loadedFeedView: some View {
        VStack(spacing: 8) {
            LikesFeedProgressBar(
                seenCount: viewModel.dailyStats.todaySeenCount,
                poolSize: viewModel.dailyStats.dailyPoolSize
            )
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if let current = viewModel.currentCard {
                DiscoverCardStackView(
                    currentCard: current,
                    nextCard: nextCard(after: current),
                    intent: viewModel.preferences.intent,
                    sparkBurstToken: viewModel.sparkBurstToken,
                    onPass: { Task { await viewModel.passCurrentCard() } },
                    onLike: { Task { await viewModel.likeCurrentCard() } },
                    onOpenProfile: { showProfileSheet = true },
                    onRewind: { Task { await viewModel.rewindLastPass() } },
                    onShowOpenerPicker: { showOpenerPicker = true }
                )
                .containerRelativeFrame(.vertical)
                .onAppear {
                    Task { await viewModel.loadMoreIfNeeded(currentCardID: current.id) }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.bottom, 120)
            }
        }
    }

    private func nextCard(after current: DiscoverCard) -> DiscoverCard? {
        guard let index = viewModel.cards.firstIndex(where: { $0.id == current.id }),
              index + 1 < viewModel.cards.count else {
            return nil
        }
        return viewModel.cards[index + 1]
    }
}
