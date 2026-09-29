//
//  PlatformMessageComposerBar.swift
//  坐标系
//
//  会话底栏 Composer（附件菜单泛型）。
//

import SwiftUI
import CoordinateModels

struct PlatformMessageComposerBar<AttachMenu: View>: View {
    @Binding var draft: String
    var placeholder: String
    var isEnabled: Bool
    var canSend: Bool
    var isFocused: FocusState<Bool>.Binding
    var replyPreview: (sender: String, text: String)? = nil
    var onCancelReply: (() -> Void)? = nil
    var onVoice: (() -> Void)? = nil
    var attachMenu: AttachMenu
    var onSend: () -> Void

    @Namespace private var composerGlass
    @Environment(\.platformChromeMeasurements) private var chromeMeasurements
    @State private var toolHeight = PlatformChromeMeasurements.fallbackComposerToolHeight

    private var usesAttachMenu: Bool { AttachMenu.self != EmptyView.self }
    private var showsMicInField: Bool { isEnabled && !canSend && onVoice != nil }
    private var toolSpacing: CGFloat { PlatformMessagesChrome.composerToolSpacing }
    private var locksFieldToToolHeight: Bool {
        !draft.contains(where: \.isNewline)
    }

    var body: some View {
        VStack {
            if let replyPreview {
                replyBar(replyPreview)
            }

            GlassEffectContainer(spacing: toolSpacing) {
                HStack(alignment: .center, spacing: toolSpacing) {
                    if isEnabled, usesAttachMenu {
                        Menu {
                            attachMenu
                        } label: {
                            Label(MessagesCopy.attach, systemImage: "plus")
                        }
                        .labelStyle(.iconOnly)
                        .platformComposerCircleStyle()
                        .fixedSize()
                        .glassEffectID("composer.plus", in: composerGlass)
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ComposerToolHeightKey.self,
                                    value: proxy.size.height
                                )
                            }
                        }
                    }

                    composerField

                    if canSend {
                        Button(MessagesCopy.send, systemImage: "arrow.up", action: onSend)
                            .labelStyle(.iconOnly)
                            .platformComposerCircleStyle(prominent: true)
                            .fixedSize()
                            .disabled(!isEnabled)
                            .glassEffectID("composer.send", in: composerGlass)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: ComposerToolHeightKey.self,
                                        value: proxy.size.height
                                    )
                                }
                            }
                    }
                }
            }
            .onPreferenceChange(ComposerToolHeightKey.self) { height in
                guard height > 0 else { return }
                toolHeight = height
                chromeMeasurements.updateComposerToolHeight(height)
            }
            .platformMessagePagePadding()
        }
        .onAppear {
            if toolHeight == PlatformChromeMeasurements.fallbackComposerToolHeight {
                toolHeight = chromeMeasurements.composerToolHeight
            }
        }
        .onChange(of: chromeMeasurements.composerToolHeight) { _, height in
            guard height > 0 else { return }
            toolHeight = height
        }
        .padding(.top, replyPreview == nil ? PlatformMessagesChrome.composerBarVerticalPadding : 0)
        .padding(.bottom, PlatformMessagesChrome.composerBarVerticalPadding)
        .opacity(isEnabled ? 1 : 0.9)
    }

    private var composerField: some View {
        HStack(alignment: .center, spacing: PlatformMessagesChrome.composerInlineSpacing) {
            TextField(
                "",
                text: $draft,
                prompt: Text(placeholder),
                axis: .vertical
            )
            .font(.body)
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .focused(isFocused)
            .disabled(!isEnabled)
            .submitLabel(.send)
            .onSubmit {
                guard canSend, isEnabled else { return }
                onSend()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsMicInField {
                Button(MessagesCopy.attachVoice, systemImage: "mic") {
                    onVoice?()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, PlatformMessagesChrome.composerFieldHorizontalPadding)
        .padding(
            .vertical,
            locksFieldToToolHeight ? 0 : chromeMeasurements.composerFieldVerticalPadding
        )
        .frame(height: locksFieldToToolHeight ? toolHeight : nil, alignment: .center)
        .platformComposerFieldChrome()
        .opacity(isEnabled ? 1 : 0.55)
    }

    private func replyBar(_ preview: (sender: String, text: String)) -> some View {
        LabeledContent {
            Button(MessagesCopy.cancelReply, systemImage: "xmark.circle.fill") {
                onCancelReply?()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
        } label: {
            Text(MessagesCopy.replyingTo(preview.sender))
            Text(preview.text)
                .lineLimit(1)
        }
        .platformMessagePagePadding()
    }
}

enum ComposerToolHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension PlatformMessageComposerBar where AttachMenu == EmptyView {
    init(
        draft: Binding<String>,
        placeholder: String,
        isEnabled: Bool,
        canSend: Bool,
        isFocused: FocusState<Bool>.Binding,
        replyPreview: (sender: String, text: String)? = nil,
        onCancelReply: (() -> Void)? = nil,
        onSend: @escaping () -> Void
    ) {
        self.init(
            draft: draft,
            placeholder: placeholder,
            isEnabled: isEnabled,
            canSend: canSend,
            isFocused: isFocused,
            replyPreview: replyPreview,
            onCancelReply: onCancelReply,
            onVoice: nil,
            attachMenu: EmptyView(),
            onSend: onSend
        )
    }
}

