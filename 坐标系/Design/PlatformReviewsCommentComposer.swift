//
//  PlatformReviewsCommentComposer.swift
//  坐标系
//
//  评论输入（同属 PlatformTextInput 模块）：
//  - 社区底栏 → `.messageComposer` / `PlatformMessageComposerBar`
//  - 陪玩履约评价 → `.form` / `PlatformReviewsWriteSheet`（订单入口；导航栏发送；可选实名/匿名）
//  禁止：详情评价区开放直写；Form 内 TextField 下方再叠发送。
//

import SwiftUI

// MARK: - Write sheet

/// App Store「写评价」式：Form 正文 + 导航栏「发送」。
/// 陪玩根评价须带 `bookingID`（订单门控）；社区/活动回复可不带。
struct PlatformReviewsWriteSheet: View {
    let target: PlatformReviewTarget
    let currentUserName: String
    @Binding var draft: String
    @Binding var replyTarget: PlatformReview?
    var title: String
    var placeholder: String
    var bookingID: UUID? = nil
    var serviceTitle: String? = nil
    var priceText: String? = nil
    var showsIdentityPicker = false
    var showsRatingPicker = false
    var onChanged: () -> Void = {}
    var onExpandParent: ((UUID) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var blockedWord: String?
    @State private var isAnonymous = false
    @State private var rating = 5
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isCompanionOrderWrite: Bool {
        target.kind == .companion && replyTarget == nil && bookingID != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                if let reply = replyTarget {
                    Section {
                        LabeledContent(PlatformReviewsCopy.replyingTo(reply.displayAuthor)) {
                            Button(PlatformReviewsCopy.cancelReply) {
                                replyTarget = nil
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                if showsIdentityPicker || isCompanionOrderWrite {
                    Section {
                        Picker(PlatformReviewsCopy.identitySection, selection: $isAnonymous) {
                            Text(PlatformReviewsCopy.identityNamed).tag(false)
                            Text(PlatformReviewsCopy.identityAnonymous).tag(true)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text(PlatformReviewsCopy.identitySection)
                    } footer: {
                        Text(PlatformReviewsCopy.identityFooter)
                    }
                }

                if showsRatingPicker || isCompanionOrderWrite {
                    Section(PlatformReviewsCopy.ratingSection) {
                        Picker(PlatformReviewsCopy.ratingSection, selection: $rating) {
                            ForEach(1...5, id: \.self) { value in
                                Text("\(value) 星").tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section {
                    TextField(
                        replyTarget == nil
                            ? placeholder
                            : PlatformReviewsCopy.replyPlaceholder(
                                author: replyTarget?.displayAuthor ?? ""
                            ),
                        text: $draft,
                        axis: .vertical
                    )
                    .platformFormTextInput(.composeBody)
                    .focused($focused)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetCancellationToolbar(PlatformReviewsCopy.writeCancel) {
                replyTarget = nil
                dismiss()
            }
            .platformSheetConfirmationToolbar(
                PlatformReviewsCopy.send,
                isEnabled: canSend,
                emphasizesWhenEnabled: true,
                action: send
            )
            .onAppear { focused = true }
        }
        .platformSheet(.form)
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
            parent: replyTarget,
            rating: (showsRatingPicker || isCompanionOrderWrite) && replyTarget == nil
                ? rating
                : nil,
            serviceTitle: replyTarget == nil ? serviceTitle : nil,
            priceText: replyTarget == nil ? priceText : nil,
            isAnonymous: (showsIdentityPicker || isCompanionOrderWrite) && replyTarget == nil
                ? isAnonymous
                : false,
            bookingID: replyTarget == nil ? bookingID : nil
        )
        if let blockedWord = outcome.blockedWord {
            self.blockedWord = blockedWord
            return
        }
        if let parentID = outcome.expandedParentID {
            onExpandParent?(parentID)
        }
        draft = ""
        replyTarget = nil
        focused = false
        onChanged()
        dismiss()
    }
}

/// 订单凭证等入口行（详情评价区勿用开放直写）。
struct PlatformReviewsWriteEntryRow: View {
    var title: String
    var systemImage: String = "square.and.pencil"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
    }
}

// MARK: - External composer (社区详情底栏)

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
                : PlatformReviewsCopy.replyPlaceholder(author: replyTarget?.displayAuthor ?? ""),
            isEnabled: true,
            canSend: canSend,
            isFocused: $focused,
            replyPreview: replyTarget.map { ($0.displayAuthor, $0.text) },
            onCancelReply: { replyTarget = nil },
            onVoiceCapture: sendVoice,
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
        apply(outcome: PlatformReviewSubmission.submit(
            draft,
            target: target,
            author: currentUserName,
            parent: replyTarget
        ))
    }

    private func sendVoice(fileURL: URL, duration: TimeInterval) {
        apply(outcome: PlatformReviewSubmission.submitVoice(
            fileURL: fileURL,
            duration: duration,
            target: target,
            author: currentUserName,
            parent: replyTarget
        ))
    }

    private func apply(outcome: PlatformReviewSubmission.Outcome) {
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
