//
//  PlatformMessageComposerBar.swift
//  坐标系
//
//  `PlatformTextInputSurface.messageComposer`：会话 / 帖评底栏。
//  文字态：左「+」+ 胶囊（空态 mic / 有字「发送」）。
//  语音：录音 → 预览（框内左播放）→ 发送；完成方钮 / 发送均在**胶囊内右侧**（与 mic 同侧）。
//  全程保键盘（TextField 不拆树）。挂载 `platformMessageComposerBottomBar`；无实心底带。
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
    /// 预览确认后发送（临时 m4a + 时长）；`nil` 时发送点按诚实提示。
    var onVoiceCapture: ((URL, TimeInterval) -> Void)? = nil
    var attachMenu: AttachMenu
    var onSend: () -> Void

    @Namespace private var composerGlass
    @Environment(\.platformChromeMeasurements) private var chromeMeasurements
    @State private var toolHeight = PlatformChromeMeasurements.fallbackComposerToolHeight
    @State private var pendingToolMessage: String?
    @State private var voiceRecorder = PlatformVoiceRecorder()

    private var usesCustomAttachMenu: Bool { AttachMenu.self != EmptyView.self }
    private var isVoiceChromeActive: Bool { voiceRecorder.isVoiceChromeActive }
    private var toolSpacing: CGFloat { PlatformMessagesChrome.composerToolSpacing }
    private var locksFieldToToolHeight: Bool {
        !isVoiceChromeActive && !draft.contains(where: \.isNewline)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let replyPreview, !isVoiceChromeActive {
                replyBar(replyPreview)
            }

            GlassEffectContainer(spacing: toolSpacing) {
                HStack(alignment: .center, spacing: toolSpacing) {
                    leadingControl
                    fieldCapsule
                        .glassEffectID("composer.field", in: composerGlass)
                }
            }
            .onPreferenceChange(ComposerToolHeightKey.self) { height in
                guard height > 0 else { return }
                toolHeight = height
                chromeMeasurements.updateComposerToolHeight(height)
            }
            .platformMessagePagePadding()
            .animation(.snappy, value: voiceRecorder.phase)
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
        .onChange(of: isEnabled) { _, enabled in
            if !enabled, isVoiceChromeActive {
                cancelVoiceSession(restoreKeyboard: false)
            }
        }
        .padding(.top, (replyPreview == nil || isVoiceChromeActive)
            ? PlatformMessagesChrome.composerBarVerticalPadding
            : 0)
        .padding(.bottom, PlatformMessagesChrome.composerBarVerticalPadding)
        .opacity(isEnabled || isVoiceChromeActive ? 1 : 0.9)
        .platformFeedbackAlert($pendingToolMessage)
    }

    // MARK: - Leading / trailing

    @ViewBuilder
    private var leadingControl: some View {
        if isVoiceChromeActive {
            Button(MessagesCopy.composerVoiceCancel, systemImage: "xmark") {
                cancelVoiceSession(restoreKeyboard: true)
            }
            .labelStyle(.iconOnly)
            .platformComposerCircleStyle()
            .fixedSize()
            .glassEffectID("composer.plus", in: composerGlass)
            .accessibilityLabel(MessagesCopy.composerVoiceCancel)
            .background(toolHeightProbe)
        } else {
            Menu {
                if usesCustomAttachMenu {
                    attachMenu
                } else {
                    Button {
                        pendingToolMessage = MessagesCopy.composerAttachUnavailable
                    } label: {
                        Label(MessagesCopy.attachPhoto, systemImage: "photo")
                    }
                    Button {
                        pendingToolMessage = MessagesCopy.composerAttachUnavailable
                    } label: {
                        Label(MessagesCopy.attachCamera, systemImage: "camera.fill")
                    }
                }
            } label: {
                Label(MessagesCopy.attach, systemImage: "plus")
            }
            .labelStyle(.iconOnly)
            .platformComposerCircleStyle()
            .disabled(!isEnabled)
            .fixedSize()
            .glassEffectID("composer.plus", in: composerGlass)
            .accessibilityHint(MessagesCopy.attach)
            .background(toolHeightProbe)
        }
    }

    private var toolHeightProbe: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ComposerToolHeightKey.self,
                value: proxy.size.height
            )
        }
    }

    // MARK: - Capsule

    private var fieldCapsule: some View {
        ZStack(alignment: .leading) {
            textFieldRow
                .opacity(isVoiceChromeActive ? 0.01 : 1)
                .allowsHitTesting(!isVoiceChromeActive && isEnabled)

            if voiceRecorder.isRecording {
                PlatformMessageComposerRecordingFieldContent(
                    recorder: voiceRecorder,
                    onStop: finishRecordingToPreview
                )
            } else if voiceRecorder.isPreview {
                PlatformMessageComposerPreviewFieldContent(
                    recorder: voiceRecorder,
                    onSend: sendVoiceCapture
                )
            }
        }
        .padding(.horizontal, PlatformMessagesChrome.composerFieldHorizontalPadding)
        .padding(
            .vertical,
            locksFieldToToolHeight ? 0 : chromeMeasurements.composerFieldVerticalPadding
        )
        .frame(minHeight: toolHeight, alignment: .center)
        .frame(height: locksFieldToToolHeight ? toolHeight : nil, alignment: .center)
        .platformComposerFieldChrome()
        .opacity(isEnabled || isVoiceChromeActive ? 1 : 0.55)
    }

    private var textFieldRow: some View {
        HStack(alignment: .center, spacing: PlatformMessagesChrome.composerInlineSpacing) {
            TextField(
                "",
                text: $draft,
                prompt: Text(placeholder),
                axis: .vertical
            )
            .platformMessageComposerTextInput()
            .focused(isFocused)
            .disabled(!isEnabled && !isVoiceChromeActive)
            .onSubmit {
                guard canSend, isEnabled, !isVoiceChromeActive else { return }
                onSend()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if canSend {
                Button(MessagesCopy.send, action: onSend)
                    .font(.body.weight(.semibold))
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundStyle(Color.accentColor)
                    .disabled(!isEnabled)
                    .accessibilityLabel(MessagesCopy.send)
            } else {
                Button(MessagesCopy.attachVoice, systemImage: "mic") {
                    startVoiceSession()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(.secondary)
                .disabled(!isEnabled)
                .accessibilityHint(MessagesCopy.composerVoiceMicHint)
            }
        }
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

    // MARK: - Voice session

    private func startVoiceSession() {
        guard isEnabled, !isVoiceChromeActive else { return }
        isFocused.wrappedValue = true
        Task {
            let started = await voiceRecorder.begin()
            if started {
                isFocused.wrappedValue = true
            } else if voiceRecorder.phase == .denied {
                pendingToolMessage = MessagesCopy.composerVoicePermissionDenied
            } else {
                pendingToolMessage = MessagesCopy.composerVoiceStartFailed
            }
        }
    }

    private func finishRecordingToPreview() {
        guard voiceRecorder.stopToPreview() else {
            pendingToolMessage = MessagesCopy.composerVoiceTooShort
            if isEnabled { isFocused.wrappedValue = true }
            return
        }
        isFocused.wrappedValue = true
    }

    private func cancelVoiceSession(restoreKeyboard: Bool) {
        voiceRecorder.cancel()
        if restoreKeyboard, isEnabled {
            isFocused.wrappedValue = true
        }
    }

    private func sendVoiceCapture() {
        guard let capture = voiceRecorder.consumePreview() else {
            pendingToolMessage = MessagesCopy.composerVoiceStartFailed
            if isEnabled { isFocused.wrappedValue = true }
            return
        }
        if let onVoiceCapture {
            onVoiceCapture(capture.url, capture.duration)
        } else {
            try? FileManager.default.removeItem(at: capture.url)
            pendingToolMessage = MessagesCopy.composerVoiceUnavailable
        }
        if isEnabled { isFocused.wrappedValue = true }
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
        onVoiceCapture: ((URL, TimeInterval) -> Void)? = nil,
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
            onVoiceCapture: onVoiceCapture,
            attachMenu: EmptyView(),
            onSend: onSend
        )
    }
}
