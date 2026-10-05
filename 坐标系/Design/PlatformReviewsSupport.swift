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
        parent: PlatformReview?,
        rating: Int? = nil,
        serviceTitle: String? = nil,
        priceText: String? = nil,
        isAnonymous: Bool = false,
        bookingID: UUID? = nil,
        voiceLocalName: String? = nil,
        voiceDuration: Double? = nil
    ) -> Outcome {
        if let error = PlatformReviewsStore.add(
            text,
            target: target,
            author: author,
            parent: parent,
            rating: rating,
            serviceTitle: serviceTitle,
            priceText: priceText,
            isAnonymous: isAnonymous,
            bookingID: bookingID,
            voiceLocalName: voiceLocalName,
            voiceDuration: voiceDuration
        ) {
            return Outcome(blockedWord: error, expandedParentID: nil)
        }
        let expandedParentID = parent?.parentID ?? parent?.id
        return Outcome(blockedWord: nil, expandedParentID: expandedParentID)
    }

    /// Composer 录音确认：临时 m4a → 本机库 → 评论（未上云）。
    static func submitVoice(
        fileURL: URL,
        duration: TimeInterval,
        target: PlatformReviewTarget,
        author: String,
        parent: PlatformReview?
    ) -> Outcome {
        guard let name = LocalMediaLibrary.importAudio(from: fileURL) else {
            try? FileManager.default.removeItem(at: fileURL)
            return Outcome(blockedWord: PlatformReviewsCopy.voiceSaveFailed, expandedParentID: nil)
        }
        try? FileManager.default.removeItem(at: fileURL)
        return submit(
            "",
            target: target,
            author: author,
            parent: parent,
            voiceLocalName: name,
            voiceDuration: duration
        )
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
        // 只读口碑：写评价在订单凭证（完成态）；此处不开放直写 / 回复。
        Section {
            PlatformReviewsCommentsHost(
                target: target,
                currentUserName: currentUserName,
                layout: .formRows,
                composerPlacement: .external,
                contentOwnerName: companion.profile.nickname,
                ownerBadgeTitle: PlatformReviewsCopy.ownerBadgeCompanion,
                emptyTitle: stats.total == 0
                    ? BuddyDetailCopy.reviewsEmpty
                    : BuddyDetailCopy.reviewsFilteredEmpty,
                emptyHint: "",
                placeholder: BuddyDetailCopy.reviewsComposerPlaceholder,
                companionFilter: stats.total > 0 ? $filter : nil,
                companionStats: stats.total > 0 ? stats : nil,
                allowsReply: false,
                onChanged: onChanged
            )
        } header: {
            PlatformReviewsHeader(count: stats.total)
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
                    Button(PlatformReviewsCopy.delete, role: .destructive, action: onDelete)
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
