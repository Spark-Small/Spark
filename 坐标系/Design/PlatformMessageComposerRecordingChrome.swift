//
//  PlatformMessageComposerRecordingChrome.swift
//  坐标系
//
//  Composer 录音 / 预览胶囊内层（官方：完成方钮 / 发送在**框内右侧**，与空态 mic 同侧）。
//  左侧圆钮取消仍由 `PlatformMessageComposerBar` 外圈承载。
//

import SwiftUI

/// 正在录音：红点 + 波形 + 时长 + **框内右侧**完成（stop）。
struct PlatformMessageComposerRecordingFieldContent: View {
    var recorder: PlatformVoiceRecorder
    var onStop: () -> Void

    private var durationLabel: String {
        Self.formatDuration(recorder.elapsed)
    }

    private var canStop: Bool {
        recorder.elapsed >= PlatformVoiceRecorder.minDuration
    }

    var body: some View {
        HStack(spacing: PlatformMessagesChrome.composerInlineSpacing) {
            recordingDot
            PlatformComposerVoiceWaveform(level: recorder.level, isActive: true)
            Text(durationLabel)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
                .accessibilityLabel(MessagesCopy.composerVoiceDurationA11y(durationLabel))
            Spacer(minLength: 0)
            Button(MessagesCopy.composerVoiceStop, systemImage: "stop.fill", action: onStop)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(Color.accentColor)
                .disabled(!canStop)
                .accessibilityLabel(MessagesCopy.composerVoiceStop)
                .accessibilityHint(MessagesCopy.composerVoiceStopHint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(MessagesCopy.composerVoiceRecordingA11y(durationLabel))
    }

    private var recordingDot: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)
    }

    static func formatDuration(_ value: TimeInterval) -> String {
        let seconds = Int(value.rounded(.down))
        if seconds < 60 { return "\(seconds)\"" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// 预览：框内左播放 + 波形 + 时长 + **框内右侧**发送。
struct PlatformMessageComposerPreviewFieldContent: View {
    var recorder: PlatformVoiceRecorder
    var onSend: () -> Void

    private var durationLabel: String {
        PlatformMessageComposerRecordingFieldContent.formatDuration(recorder.previewDuration)
    }

    var body: some View {
        HStack(spacing: PlatformMessagesChrome.composerInlineSpacing) {
            Button {
                recorder.togglePreviewPlayback()
            } label: {
                Label(
                    recorder.isPlayingPreview
                        ? MessagesCopy.composerVoicePause
                        : MessagesCopy.composerVoicePlay,
                    systemImage: recorder.isPlayingPreview ? "pause.fill" : "play.fill"
                )
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .controlSize(.small)
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel(
                recorder.isPlayingPreview
                    ? MessagesCopy.composerVoicePause
                    : MessagesCopy.composerVoicePlay
            )
            .accessibilityHint(MessagesCopy.composerVoicePlayHint)

            PlatformComposerVoiceWaveform(
                level: recorder.isPlayingPreview ? 0.55 : 0.25,
                isActive: recorder.isPlayingPreview
            )
            Text(durationLabel)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
                .accessibilityLabel(MessagesCopy.composerVoiceDurationA11y(durationLabel))
            Spacer(minLength: 0)
            Button(MessagesCopy.send, action: onSend)
                .font(.body.weight(.semibold))
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel(MessagesCopy.send)
                .accessibilityHint(MessagesCopy.composerVoiceSendHint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

/// 轻量电平波形（Design 内自给，不依赖搭子 Feature）。
struct PlatformComposerVoiceWaveform: View {
    var level: Double
    var isActive: Bool
    var barCount = 14

    var body: some View {
        TimelineView(.animation(minimumInterval: isActive ? 0.08 : nil, paused: !isActive)) { timeline in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let phase = sin(
                        timeline.date.timeIntervalSinceReferenceDate * 6
                            + Double(index) * 0.45
                    )
                    let height = 5 + (abs(phase) * 0.55 + level * 0.45) * 12
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color.accentColor.opacity(isActive ? 0.9 : 0.4))
                        .frame(width: 3, height: height)
                }
            }
            .frame(height: 20, alignment: .center)
        }
        .accessibilityHidden(true)
    }
}
