// Module: SparkCommunity — Reply composer for post detail.

import SparkDesignSystem
import SwiftUI

struct CommunityReplyComposer: View {
    @Binding var draft: String
    let isSending: Bool
    let errorMessage: String?
    let onSend: () -> Void

    @FocusState private var isFieldFocused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: 12) {
                TextField(
                    String(
                        localized: "community.reply.placeholder",
                        defaultValue: "说点什么…",
                        comment: "Reply placeholder"
                    ),
                    text: $draft,
                    axis: .vertical
                )
                .font(.body)
                .lineLimit(1 ... 4)
                .focused($isFieldFocused)
                .submitLabel(.send)
                .onSubmit(sendIfPossible)
                .padding(.horizontal, SparkLayoutMetrics.composerFieldHorizontalPadding)
                .padding(.vertical, SparkLayoutMetrics.composerFieldVerticalPadding)
                .background(
                    .quaternary,
                    in: RoundedRectangle(
                        cornerRadius: SparkLayoutMetrics.conversationComposerCornerRadius,
                        style: .continuous
                    )
                )

                Button(action: sendIfPossible) {
                    Group {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .tint(canSend ? Color.accentColor : Color.secondary)
                .disabled(!canSend)
                .sparkMinimumTouchTarget()
                .accessibilityLabel(
                    String(localized: "community.reply.send", defaultValue: "发送", comment: "Send reply")
                )
            }
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .background(.bar)
        .scrollDismissesKeyboard(.interactively)
    }

    private func sendIfPossible() {
        guard canSend else { return }
        onSend()
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Reply composer — empty") {
        CommunityReplyComposer(
            draft: .constant(""),
            isSending: false,
            errorMessage: nil,
            onSend: {}
        )
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Reply composer — draft") {
        CommunityReplyComposer(
            draft: .constant("赞同！"),
            isSending: false,
            errorMessage: nil,
            onSend: {}
        )
    }
}
