//
//  PlatformVoiceNoteChip.swift
//  坐标系
//
//  评论 / 会话列表内本机语音条：播放按钮 + 时长（AVAudioPlayer）。
//

import AVFoundation
import SwiftUI

struct PlatformVoiceNoteChip: View {
    var fileURL: URL?
    var duration: TimeInterval

    @State private var isPlaying = false
    @State private var player: AVAudioPlayer?
    @State private var finishRelay: VoiceNoteFinishRelay?

    private var durationLabel: String {
        let seconds = Int(duration.rounded(.down))
        if seconds < 60 { return "\(seconds)\"" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: PlatformMessagesChrome.composerInlineSpacing) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.semibold))
                Text(durationLabel)
                    .font(.subheadline.monospacedDigit())
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, PlatformMessagesChrome.composerFieldHorizontalPadding)
            .padding(.vertical, PlatformConversationListRow.textToSecondarySpacing)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            }
        }
        .buttonStyle(.plain)
        .disabled(fileURL == nil)
        .accessibilityLabel(isPlaying ? MessagesCopy.composerVoicePause : MessagesCopy.composerVoicePlay)
        .accessibilityValue(MessagesCopy.composerVoiceDurationA11y(durationLabel))
        .onDisappear { stop() }
    }

    private func toggle() {
        if isPlaying {
            stop()
            return
        }
        guard let fileURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.defaultToSpeaker])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: fileURL)
            let relay = VoiceNoteFinishRelay {
                Task { @MainActor in
                    isPlaying = false
                    self.player = nil
                    finishRelay = nil
                }
            }
            player.delegate = relay
            player.prepareToPlay()
            guard player.play() else { return }
            self.player = player
            self.finishRelay = relay
            isPlaying = true
        } catch {
            stop()
        }
    }

    private func stop() {
        player?.stop()
        player = nil
        finishRelay = nil
        isPlaying = false
    }
}

private final class VoiceNoteFinishRelay: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
