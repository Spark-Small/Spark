//
//  PlatformReviewsSupport.swift
//  坐标系
//
//  评价提交辅助、Rated Tab、List 行修饰。
//

import SwiftUI

// MARK: - Submission helper

@MainActor
enum PlatformReviewSubmission {
    struct Outcome {
        var blockedWord: String?
        var expandedParentID: UUID?
    }

    static func submit(
        _ text: String,
        target: PlatformReviewTarget,
        author: String,
        parent: PlatformReview?
    ) -> Outcome {
        if let error = PlatformReviewsStore.add(
            text,
            target: target,
            author: author,
            parent: parent
        ) {
            return Outcome(blockedWord: error, expandedParentID: nil)
        }
        let expandedParentID = parent?.parentID ?? parent?.id
        return Outcome(blockedWord: nil, expandedParentID: expandedParentID)
    }
}

// MARK: - Rated tab (companion)

struct PlatformReviewsRatedTab: View {
    let companion: PaidCompanion
    let currentUserName: String
    var onChanged: () -> Void = {}

    @State private var filter: PlatformReviewFilter = .all

    private var target: PlatformReviewTarget {
        .companion(companion.id)
    }

    private var stats: PlatformReviewStats {
        PlatformReviewsStore.stats(for: target)
    }

    var body: some View {
        Section {
            PlatformReviewsCommentsHost(
                target: target,
                currentUserName: currentUserName,
                layout: .formRows,
                contentOwnerName: companion.profile.nickname,
                ownerBadgeTitle: "陪玩",
                emptyTitle: stats.total == 0
                    ? BuddyDetailCopy.reviewsEmpty
                    : BuddyDetailCopy.reviewsFilteredEmpty,
                emptyHint: BuddyDetailCopy.reviewsFooter,
                placeholder: BuddyDetailCopy.reviewsComposerPlaceholder,
                companionFilter: stats.total > 0 ? $filter : nil,
                companionStats: stats.total > 0 ? stats : nil,
                onChanged: onChanged
            )
        } header: {
            PlatformReviewsHeader(count: stats.total)
        } footer: {
            Text(BuddyDetailCopy.reviewsFooter)
        }
    }
}

struct FormAccessoryRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .platformMessagesSeparatorsHidden()
    }
}

struct PlatformReviewsListRowModifier: ViewModifier {
    var enabled = true

    func body(content: Content) -> some View {
        if enabled {
            content.platformMessagesSeparatorsHidden()
        } else {
            content
        }
    }
}

struct ReviewRowInteractionModifier: ViewModifier {
    let review: PlatformReview
    let currentUserName: String
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if review.isOwned(by: currentUserName) {
                    Button("删除", role: .destructive, action: onDelete)
                }
            }
    }
}

struct OptionalListRowBackgroundModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .listRowBackground(Color.clear)
                .platformMessagesSeparatorsHidden()
        } else {
            content
        }
    }
}
