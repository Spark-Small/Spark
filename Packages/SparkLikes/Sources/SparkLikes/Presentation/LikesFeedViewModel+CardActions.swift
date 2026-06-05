// Module: SparkLikes — Discover card actions and match presentation.

import Foundation
import SparkCore

extension LikesFeedViewModel {
    // MARK: - Card actions

    enum LikePresentationSource: Sendable {
        case feed(advanceOnNonMatch: Bool)
        case inbound
    }

    public func advanceToNextCard() {
        guard !cards.isEmpty else { return }
        let removeIndex = min(currentIndex, cards.count - 1)
        cards.remove(at: removeIndex)
        if cards.isEmpty {
            currentIndex = 0
            loadState = .empty
            return
        }
        if currentIndex >= cards.count {
            currentIndex = cards.count - 1
        }
    }

    public func likeQuestion(_ questionID: String) {
        pendingLikedQuestionID = questionID
        statusMessage = String(
            localized: "likes.question.liked.pending",
            defaultValue: "已标记这条回答，发送喜欢时会附上",
            comment: "Question liked pending"
        )
    }

    public func likeCurrentCard(opener: String? = nil) async {
        guard guardDiscoverAction(), let card = currentCard, !isPerformingAction else { return }
        if isDailyPoolExhausted {
            loadState = .empty
            return
        }
        isPerformingAction = true
        defer { isPerformingAction = false }
        let request = SendLikeRequest(
            userID: card.userID,
            intensity: .like,
            opener: opener ?? pendingOpener,
            likedQuestionID: pendingLikedQuestionID
        )
        do {
            let result = try await submitLike(request)
            pendingOpener = nil
            pendingLikedQuestionID = nil
            recordBrowseProgress()
            await refreshDailyStats()
            applyLikeResult(result, card: card, source: .feed(advanceOnNonMatch: true))
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func sparkCurrentCard() async {
        guard guardDiscoverAction(), let card = currentCard, !isPerformingAction else { return }
        guard dailyStats.sparkChargesRemaining > 0 else {
            setStatusMessage(from: LikesError.sparkChargesExhausted)
            return
        }
        if isDailyPoolExhausted {
            loadState = .empty
            return
        }
        isPerformingAction = true
        defer { isPerformingAction = false }
        let request = SendLikeRequest(
            userID: card.userID,
            intensity: .spark,
            opener: pendingOpener,
            likedQuestionID: pendingLikedQuestionID
        )
        do {
            let result = try await submitLike(request)
            pendingOpener = nil
            pendingLikedQuestionID = nil
            sparkBurstToken += 1
            recordBrowseProgress()
            await refreshDailyStats()
            applyLikeResult(result, card: card, source: .feed(advanceOnNonMatch: true))
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func likeInboundUser(_ userID: UserID, opener: String? = nil) async {
        guard guardDiscoverAction(), !isPerformingAction else { return }
        guard let item = inboundItems.first(where: { $0.userID == userID }) else { return }
        let card = item.card
        isPerformingAction = true
        defer { isPerformingAction = false }
        let request = SendLikeRequest(userID: userID, intensity: .like, opener: opener)
        do {
            let result = try await submitLike(request)
            inboundItems.removeAll { $0.userID == userID }
            applyLikeResult(result, card: card, source: .inbound)
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func passCurrentCard() async {
        guard let card = currentCard, !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            try await submitPass(userID: card.userID)
            recordBrowseProgress()
            await refreshDailyStats()
            advanceToNextCard()
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func friendRequestCurrentCard() async {
        guard guardDiscoverAction(), let card = currentCard, !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            _ = try await submitFriendRequest(userID: card.userID)
            friendRequestSuccessToken += 1
            recordBrowseProgress()
            statusMessage = String(
                localized: "likes.friend.sent",
                defaultValue: "好友请求已发送",
                comment: "Friend request sent"
            )
            advanceToNextCard()
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func rewindLastPass() async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            guard let card = try await rewindPass() else {
                statusMessage = String(
                    localized: "likes.error.rewindUnavailable",
                    defaultValue: "今天无法撤回，或没有可撤回的人",
                    comment: "Rewind unavailable"
                )
                return
            }
            LikesTelemetry.rewindUsed()
            if loadState == .empty {
                loadState = .loaded
            }
            cards.insert(card, at: min(currentIndex, cards.count))
            statusMessage = String(
                localized: "likes.rewind.done",
                defaultValue: "已撤回上一位",
                comment: "Rewind done"
            )
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func reportAndBlockCurrentCard(reason: LikesReportReason, detail: String?) async {
        guard let card = currentCard, !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            try await reportAndBlockUser(userID: card.userID, reason: reason.wireValue, detail: detail)
            statusMessage = String(
                localized: "likes.report.done",
                defaultValue: "已举报并屏蔽",
                comment: "Report done"
            )
            advanceToNextCard()
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func completeMatchWithMessage(_ message: String?) {
        if let message, !message.isEmpty {
            LikesTelemetry.firstMessageSent(source: "match_sheet")
        }
        clearMatchPresentation()
        advanceToNextCard()
    }

    public func dismissMatchWithoutMessage() {
        clearMatchPresentation()
        advanceToNextCard()
    }

    public func clearMatchPresentation() {
        pendingMatch = nil
        pendingMatchPeerName = nil
        pendingMatchCard = nil
    }

    public func clearDirectMessagePresentation() {
        pendingDirectMessage = nil
    }

    private func applyLikeResult(_ result: LikeActionResult, card: DiscoverCard, source: LikePresentationSource) {
        switch result.outcome {
        case .matched:
            presentMatch(result: result, card: card)
        case .pending:
            statusMessage = Self.pendingLikeStatusMessage
            if case .feed(advanceOnNonMatch: true) = source {
                advanceToNextCard()
            }
        case .alreadyConnected:
            if let threadID = result.threadID {
                pendingDirectMessage = PendingDirectMessage(threadID: threadID, peerName: card.displayName)
            } else {
                statusMessage = Self.alreadyConnectedStatusMessage
            }
            if case .feed(advanceOnNonMatch: true) = source {
                advanceToNextCard()
            }
        case .sent:
            if case .feed(advanceOnNonMatch: true) = source {
                advanceToNextCard()
            }
        }
    }

    private func presentMatch(result: LikeActionResult, card: DiscoverCard) {
        pendingMatch = result
        pendingMatchPeerName = card.displayName
        pendingMatchCard = card
        LikesTelemetry.matchSheetShown()
    }

    private func recordBrowseProgress() {
        cardsBrowsedThisSession += 1
        if cardsBrowsedThisSession >= 5, cards.count <= 1 {
            showPreferencesHint = true
        }
    }

    private static var pendingLikeStatusMessage: String {
        String(
            localized: "likes.like.pending",
            defaultValue: "已喜欢，等对方回应",
            comment: "Like pending"
        )
    }

    private static var alreadyConnectedStatusMessage: String {
        String(
            localized: "likes.like.connected",
            defaultValue: "你们已经可以聊天了",
            comment: "Already connected"
        )
    }

    func feedQuery(cursor: String?) -> LikesFeedQuery {
        LikesFeedQuery(
            cursor: cursor,
            genderPreference: preferences.genderPreference,
            intent: preferences.intent
        )
    }
}
