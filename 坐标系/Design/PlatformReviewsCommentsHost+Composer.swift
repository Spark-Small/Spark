//
//  PlatformReviewsCommentsHost+Composer.swift
//  坐标系
//
//  评论宿主：底栏 / 行内写评价 Sheet 与提交动作。
//

import SwiftUI

extension PlatformReviewsCommentsHost {
    var bottomComposer: some View {
        PlatformMessageComposerBar(
            draft: draftBinding,
            placeholder: replyTarget == nil
                ? placeholder
                : PlatformReviewsCopy.replyPlaceholder(author: replyTarget?.displayAuthor ?? ""),
            isEnabled: true,
            canSend: canSend,
            isFocused: $focused,
            replyPreview: replyTarget.map { ($0.displayAuthor, $0.text) },
            onCancelReply: { replyTarget = nil },
            onVoiceCapture: sendVoice,
            onSend: send
        )
    }

    @ViewBuilder
    var inlineComposerRow: some View {
        if showsInlineComposer {
            PlatformReviewsWriteEntryRow(title: PlatformReviewsCopy.writeReviewTitle) {
                showWriteSheet = true
            }
            .sheet(isPresented: $showWriteSheet) {
                PlatformReviewsWriteSheet(
                    target: target,
                    currentUserName: currentUserName,
                    draft: draftBinding,
                    replyTarget: replyTargetBinding,
                    title: replyTarget == nil
                        ? PlatformReviewsCopy.writeReviewTitle
                        : PlatformReviewsCopy.writeReplyTitle,
                    placeholder: placeholder,
                    onChanged: {
                        reload()
                        onChanged()
                    },
                    onExpandParent: { expandedIDs.insert($0) }
                )
            }
            .onChange(of: replyTarget?.id) { _, id in
                if showsInlineComposer, id != nil {
                    showWriteSheet = true
                }
            }
        }
    }

    func reload() {
        reviews = PlatformReviewsStore.reviews(for: target)
        autoExpandCompactThreads()
    }

    /// ≤2 条回复默认展开一次，避免每次 reload 把用户收起的楼又拉开。
    func autoExpandCompactThreads() {
        guard !didApplyDefaultExpansion else { return }
        didApplyDefaultExpansion = true
        for root in PlatformReviewCatalog.sortedRoots(reviews) {
            let replyCount = reviews.filter { $0.parentID == root.id }.count
            if replyCount > 0, replyCount <= 2 {
                expandedIDs.insert(root.id)
            }
        }
    }

    func beginReply(to review: PlatformReview) {
        guard allowsReply else { return }
        replyTarget = review
        let rootID = review.parentID ?? review.id
        expandedIDs.insert(rootID)
        focused = true
    }

    func toggleLike(_ review: PlatformReview) {
        PlatformReviewsStore.toggleLike(reviewID: review.id, target: target)
        reload()
        onChanged()
    }

    func toggleDislike(_ review: PlatformReview) {
        PlatformReviewsStore.toggleDislike(reviewID: review.id, target: target)
        reload()
        onChanged()
    }

    func send() {
        applySend(outcome: PlatformReviewSubmission.submit(
            draft,
            target: target,
            author: currentUserName,
            parent: replyTarget
        ))
    }

    func sendVoice(fileURL: URL, duration: TimeInterval) {
        applySend(outcome: PlatformReviewSubmission.submitVoice(
            fileURL: fileURL,
            duration: duration,
            target: target,
            author: currentUserName,
            parent: replyTarget
        ))
    }

    private func applySend(outcome: PlatformReviewSubmission.Outcome) {
        if let blockedWord = outcome.blockedWord {
            self.blockedWord = blockedWord
            return
        }
        if let parentID = outcome.expandedParentID {
            expandedIDs.insert(parentID)
        }
        draft = ""
        replyTarget = nil
        focused = false
        reload()
        onChanged()
    }

    func delete(_ review: PlatformReview) {
        if replyTarget?.id == review.id { replyTarget = nil }
        PlatformReviewsStore.delete(reviewID: review.id, target: target, author: currentUserName)
        reload()
        onChanged()
    }
}
