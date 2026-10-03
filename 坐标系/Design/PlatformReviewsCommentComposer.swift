//
//  PlatformReviewsCommentComposer.swift
//  坐标系
//
//  外部评论输入（社区详情底栏等）。
//

import SwiftUI

// MARK: - External composer (社区详情底栏)

/// 与 `PlatformReviewsCommentsHost` 共用 draft / reply / 展开态。
struct PlatformReviewsCommentComposer: View {
    let target: PlatformReviewTarget
    let currentUserName: String
    @Binding var draft: String
    @Binding var replyTarget: PlatformReview?
    var expandedThreadIDs: Binding<Set<UUID>>? = nil
    var placeholder: String
    var onChanged: () -> Void = {}

    @State private var blockedWord: String?
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        PlatformMessageComposerBar(
            draft: $draft,
            placeholder: replyTarget == nil
                ? placeholder
                : PlatformReviewsCopy.replyPlaceholder(author: replyTarget?.author ?? ""),
            isEnabled: true,
            canSend: canSend,
            isFocused: $focused,
            replyPreview: replyTarget.map { ($0.author, $0.text) },
            onCancelReply: { replyTarget = nil },
            onSend: send
        )
        .alert(PlatformReviewsCopy.needsEditTitle, isPresented: Binding(
            get: { blockedWord != nil },
            set: { if !$0 { blockedWord = nil } }
        )) {
            Button(PlatformReviewsCopy.needsEditDismiss, role: .cancel) {}
        } message: {
            Text(blockedWord ?? "")
        }
    }

    private func send() {
        let outcome = PlatformReviewSubmission.submit(
            draft,
            target: target,
            author: currentUserName,
            parent: replyTarget
        )
        if let blockedWord = outcome.blockedWord {
            self.blockedWord = blockedWord
            return
        }
        if let parentID = outcome.expandedParentID {
            expandedThreadIDs?.wrappedValue.insert(parentID)
        }
        draft = ""
        replyTarget = nil
        focused = false
        onChanged()
    }
}
