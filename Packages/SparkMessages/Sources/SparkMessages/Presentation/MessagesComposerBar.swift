// Module: SparkMessages — Thread composer (system bar + quaternary field).

import PhotosUI
import SparkCore
import SparkDesignSystem
import SwiftUI

struct MessagesComposerBar: View {
    @Binding var draft: String
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let isSending: Bool
    let sendSuccessToken: Int
    let onSend: () -> Void

    @FocusState private var isFieldFocused: Bool
    @State private var showsAttachmentTray = false

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsAttachmentTray {
                attachmentTray
                    .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
                    .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
            }

            HStack(alignment: .bottom, spacing: 12) {
                Button {
                    showsAttachmentTray.toggle()
                    if showsAttachmentTray {
                        isFieldFocused = false
                    }
                } label: {
                    Image(systemName: showsAttachmentTray ? "xmark.circle" : "plus.circle")
                        .font(.title3)
                        .frame(
                            minWidth: SparkLayoutMetrics.minimumTouchTarget,
                            minHeight: SparkLayoutMetrics.minimumTouchTarget
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(
                    String(
                        localized: "messages.composer.attachments",
                        defaultValue: "附件",
                        comment: "Attachment tray"
                    )
                )

                TextField(
                    String(localized: "messages.composer.placeholder", defaultValue: "输入消息…", comment: "Composer"),
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
                .sensoryFeedback(.success, trigger: sendSuccessToken)
                .accessibilityLabel(
                    String(localized: "messages.composer.send", defaultValue: "发送", comment: "Send message")
                )
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.composerFieldVerticalPadding)
        }
        .background(.bar)
        .scrollDismissesKeyboard(.interactively)
    }

    private var attachmentTray: some View {
        HStack(spacing: 20) {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .frame(width: 52, height: 52)
                        .background(
                            .quaternary,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    Text(
                        String(localized: "messages.composer.attachPhoto", defaultValue: "照片", comment: "Attach photo")
                    )
                    .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .onAppear {
                SparkPermissionTelemetry.trackPhotoLibraryAccess(source: .messagesComposerPhoto)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                if item != nil {
                    showsAttachmentTray = false
                }
            }
            Spacer()
        }
    }

    private func sendIfPossible() {
        guard canSend else { return }
        onSend()
    }
}
