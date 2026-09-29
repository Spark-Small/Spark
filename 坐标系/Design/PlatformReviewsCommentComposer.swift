//
//  PlatformReviewsCommentComposer.swift
//  坐标系
//
//  外部评论输入（社区详情底栏等）。
//

import SwiftUI

// MARK: - External composer (社区详情底栏)

/// 与 `PlatformReviewsCommentsHost` 共用 draft / reply 状态的底栏输入。
struct PlatformReviewsCommentComposer: View {
    let target: PlatformReviewTarget
    let currentUserName: String
    @Binding var draft: String
    @Binding var replyTarget: PlatformReview?
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
                : "回复 \(replyTarget?.author ?? "")…",
            isEnabled: true,
            canSend: canSend,
            isFocused: $focused,
            replyPreview: replyTarget.map { ($0.author, $0.text) },
            onCancelReply: { replyTarget = nil },
            onSend: send
        )
        .alert("评论需要修改", isPresented: Binding(
            get: { blockedWord != nil },
            set: { if !$0 { blockedWord = nil } }
        )) {
            Button("知道了", role: .cancel) {}
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
        draft = ""
        replyTarget = nil
        focused = false
        onChanged()
    }
}

