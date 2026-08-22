//
//  BuddyVoiceIntroViews.swift
//  坐标系
//
//  语音介绍：资料页对外播放（Form 行）+ 个人资料内录制。
//  对齐 Soul / 探探等「资料卡上的声音名片」，而非发现列表运营条。
//

import SwiftUI

// MARK: - Presentation helpers

enum VoiceIntroPresentation {
    static func hasIntro(_ duration: Double?) -> Bool {
        guard let duration else { return false }
        return duration > 0
    }

    static func durationText(_ duration: Double?) -> String {
        guard let duration, duration > 0 else { return "0\"" }
        let seconds = Int(duration.rounded())
        if seconds < 60 { return "\(seconds)\"" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

extension BuddyProfile {
    var hasVoiceIntro: Bool { VoiceIntroPresentation.hasIntro(voiceIntroDuration) }
    var voiceIntroDurationText: String { VoiceIntroPresentation.durationText(voiceIntroDuration) }
}

// MARK: - Public profile player（资料页）

/// 他人资料上的语音介绍：系统 Form 行内播放，不嵌自定义卡片壳。
struct BuddyPublicVoiceIntroRow: View {
    let duration: Double
    var caption: String?
    var tint: Color = .accentColor

    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var playbackTask: Task<Void, Never>?

    init(profile: BuddyProfile, tint: Color = .accentColor) {
        duration = profile.voiceIntroDuration ?? 0
        caption = profile.voiceIntroCaption
        self.tint = tint
    }

    init(duration: Double, caption: String? = nil, tint: Color = .accentColor) {
        self.duration = duration
        self.caption = caption
        self.tint = tint
    }

    var body: some View {
        Button(action: togglePlayback) {
            HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(tint, in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading) {
                    HStack(spacing: PlatformMetrics.minContentGap) {
                        BuddyVoiceIntroWaveform(isAnimating: isPlaying, tint: tint)
                        Text(VoiceIntroPresentation.durationText(duration))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tint)
                            .monospacedDigit()
                    }

                    Text(displayCaption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(isPlaying ? 0.92 : 1)
            .overlay(alignment: .bottom) {
                if isPlaying {
                    ProgressView(value: playbackProgress)
                        .tint(tint)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isPlaying
                ? BuddyVoiceIntroCopy.pauseAccessibility
                : BuddyVoiceIntroCopy.playAccessibility
        )
        .accessibilityValue(VoiceIntroPresentation.durationText(duration))
        .accessibilityHint(displayCaption)
        .onDisappear { stopPlayback() }
    }

    private var displayCaption: String {
        let trimmed = caption?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty { return BuddyVoiceIntroCopy.publicFallbackCaption }
        return trimmed
    }

    private func togglePlayback() {
        guard duration > 0 else { return }
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback(duration: duration)
        }
    }

    private func startPlayback(duration: Double) {
        stopPlayback()
        isPlaying = true
        playbackProgress = 0
        let totalSteps = max(1, Int(duration * 10))
        playbackTask = Task {
            for step in 0...totalSteps {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    playbackProgress = Double(step) / Double(totalSteps)
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
            await MainActor.run { stopPlayback() }
        }
    }

    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
        playbackProgress = 0
    }
}

struct BuddyVoiceIntroWaveform: View {
    var isAnimating: Bool
    var tint: Color = .accentColor
    var barCount = 12

    var body: some View {
        TimelineView(.animation(minimumInterval: isAnimating ? 0.08 : nil, paused: !isAnimating)) { timeline in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let phase = isAnimating
                        ? sin(timeline.date.timeIntervalSinceReferenceDate * 5 + Double(index) * 0.55)
                        : sin(Double(index) * 0.75)
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(tint.opacity(isAnimating ? 0.9 : 0.45))
                        .frame(width: 3, height: 6 + abs(phase) * 10)
                }
            }
            .frame(height: 18, alignment: .center)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Recorder sheet（个人资料）

struct BuddyVoiceIntroRecorderSheet: View {
    var initialDuration: Double?
    var initialCaption: String = ""
    var onSave: (Double, String) -> Void
    var onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draftDuration: Double?
    @State private var draftCaption = ""
    @State private var isRecording = false
    @State private var recordingElapsed: TimeInterval = 0
    @State private var recordingTask: Task<Void, Never>?

    private let minDuration: TimeInterval = 3
    private let maxDuration: TimeInterval = 60

    private var effectiveDuration: Double? {
        draftDuration ?? initialDuration
    }

    private var canSave: Bool {
        guard let effectiveDuration, effectiveDuration >= minDuration else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack {
                        BuddyVoiceIntroWaveform(
                            isAnimating: isRecording,
                            tint: .accentColor,
                            barCount: 16
                        )
                        .frame(maxWidth: .infinity)

                        Text(durationLabel)
                            .font(.title2.bold())
                            .monospacedDigit()
                            .foregroundStyle(isRecording ? Color.accentColor : .primary)
                            .accessibilityLabel("录音时长 \(durationLabel)")

                        Text(
                            isRecording
                                ? BuddyVoiceIntroCopy.releaseToFinish
                                : BuddyVoiceIntroCopy.holdToRecord
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                        recordButton
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PlatformMetrics.detailCompactSpacing)
                } footer: {
                    Text(BuddyVoiceIntroCopy.recordHint)
                }

                Section {
                    TextField(BuddyVoiceIntroCopy.captionPlaceholder, text: $draftCaption, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text(BuddyVoiceIntroCopy.captionLabel)
                }

                if effectiveDuration != nil {
                    Section {
                        Button(BuddyVoiceIntroCopy.removeVoice, role: .destructive) {
                            onRemove()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(BuddyVoiceIntroCopy.recordSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyVoiceIntroCopy.save) {
                        guard let effectiveDuration else { return }
                        onSave(effectiveDuration, draftCaption)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                draftDuration = initialDuration
                draftCaption = initialCaption
            }
            .onDisappear {
                stopRecording(save: false)
            }
        }
        .platformSheet(.confirm)
    }

    private var durationLabel: String {
        let seconds = Int((isRecording ? recordingElapsed : (effectiveDuration ?? 0)).rounded())
        if seconds < 60 { return "\(seconds)\"" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var recordButton: some View {
        Circle()
            .fill(isRecording ? Color.accentColor : Color.accentColor.opacity(0.18))
            .frame(width: 72, height: 72)
            .overlay {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: isRecording ? 0 : 3)
                    .frame(width: 72, height: 72)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(isRecording ? .white : Color.accentColor)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isRecording { startRecording() }
                    }
                    .onEnded { _ in
                        stopRecording(save: true)
                    }
            )
            .accessibilityLabel(BuddyVoiceIntroCopy.holdToRecord)
            .accessibilityHint(BuddyVoiceIntroCopy.releaseToFinish)
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        recordingElapsed = 0
        recordingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                await MainActor.run {
                    recordingElapsed += 0.1
                    if recordingElapsed >= maxDuration {
                        stopRecording(save: true)
                    }
                }
            }
        }
    }

    private func stopRecording(save: Bool) {
        recordingTask?.cancel()
        recordingTask = nil
        guard isRecording else { return }
        isRecording = false
        if save, recordingElapsed >= minDuration {
            draftDuration = recordingElapsed
        }
    }
}
