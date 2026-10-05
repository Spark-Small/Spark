//
//  PlatformVoiceRecorder.swift
//  坐标系
//
//  消息底栏本机语音：录（AVAudioRecorder）→ 预览播放（AVAudioPlayer）→ 发送。
//  临时 m4a；持久化由 Features → LocalMediaLibrary。真 IM 上传仍属 B5。
//

import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class PlatformVoiceRecorder {
    enum Phase: Equatable {
        case idle
        case recording
        case preview
        case denied
        case failed
    }

    static let maxDuration: TimeInterval = 60
    static let minDuration: TimeInterval = 1

    private(set) var phase: Phase = .idle
    private(set) var elapsed: TimeInterval = 0
    /// 录音电平 0…1；预览播放时用时间相位即可。
    private(set) var level: Double = 0
    private(set) var previewDuration: TimeInterval = 0
    private(set) var isPlayingPreview = false

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var playerRelay: PlayerFinishRelay?
    private var meterTask: Task<Void, Never>?
    private var fileURL: URL?

    var isRecording: Bool { phase == .recording }
    var isPreview: Bool { phase == .preview }
    var isVoiceChromeActive: Bool { phase == .recording || phase == .preview }

    func begin() async -> Bool {
        discardAll()
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            phase = .denied
            return false
        }

        do {
            try activateSession(forPlayback: false)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("composer-voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                phase = .failed
                deactivateSession()
                return false
            }

            self.recorder = recorder
            self.fileURL = url
            self.elapsed = 0
            self.level = 0
            self.previewDuration = 0
            self.phase = .recording
            startMetering()
            return true
        } catch {
            phase = .failed
            return false
        }
    }

    /// 结束录音进入预览（可播放）；过短则丢弃并回到 idle。
    @discardableResult
    func stopToPreview() -> Bool {
        stopMetering()
        stopPreviewPlayback()
        guard phase == .recording, let recorder, let fileURL else {
            discardAll()
            return false
        }
        let duration = max(recorder.currentTime, elapsed)
        recorder.stop()
        self.recorder = nil

        guard duration >= Self.minDuration,
              FileManager.default.fileExists(atPath: fileURL.path)
        else {
            try? FileManager.default.removeItem(at: fileURL)
            self.fileURL = nil
            elapsed = 0
            level = 0
            phase = .idle
            deactivateSession()
            return false
        }

        self.previewDuration = duration
        self.elapsed = duration
        self.level = 0
        self.phase = .preview
        // 预览播放仍需 session；保持 active。
        return true
    }

    func togglePreviewPlayback() {
        guard phase == .preview, let fileURL else { return }
        if isPlayingPreview {
            stopPreviewPlayback()
            return
        }
        do {
            try activateSession(forPlayback: true)
            let player = try AVAudioPlayer(contentsOf: fileURL)
            let relay = PlayerFinishRelay { [weak self] in
                Task { @MainActor in
                    self?.isPlayingPreview = false
                    self?.player = nil
                    self?.playerRelay = nil
                }
            }
            player.delegate = relay
            player.prepareToPlay()
            guard player.play() else { return }
            self.player = player
            self.playerRelay = relay
            self.isPlayingPreview = true
        } catch {
            isPlayingPreview = false
            player = nil
            playerRelay = nil
        }
    }

    /// 取出预览文件供发送；调用方负责落盘/删除。
    func consumePreview() -> (url: URL, duration: TimeInterval)? {
        stopPreviewPlayback()
        guard phase == .preview, let fileURL else {
            discardAll()
            return nil
        }
        let duration = previewDuration
        self.fileURL = nil
        self.previewDuration = 0
        self.elapsed = 0
        self.level = 0
        self.phase = .idle
        deactivateSession()
        return (fileURL, duration)
    }

    /// 丢弃录音/预览并复位。
    func cancel() {
        discardAll()
    }

    // MARK: - Private

    private func discardAll() {
        stopMetering()
        stopPreviewPlayback()
        recorder?.stop()
        recorder = nil
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        fileURL = nil
        elapsed = 0
        level = 0
        previewDuration = 0
        phase = .idle
        deactivateSession()
    }

    private func stopPreviewPlayback() {
        player?.stop()
        player = nil
        playerRelay = nil
        isPlayingPreview = false
    }

    private func startMetering() {
        stopMetering()
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(80))
                await MainActor.run {
                    guard let self, self.phase == .recording, let recorder = self.recorder else { return }
                    recorder.updateMeters()
                    let power = recorder.averagePower(forChannel: 0)
                    self.level = Double(max(0, min(1, (power + 60) / 60)))
                    self.elapsed = min(recorder.currentTime, Self.maxDuration)
                    if self.elapsed >= Self.maxDuration {
                        _ = self.stopToPreview()
                    }
                }
            }
        }
    }

    private func stopMetering() {
        meterTask?.cancel()
        meterTask = nil
    }

    private func activateSession(forPlayback: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
        try session.setActive(true)
        if forPlayback {
            try session.overrideOutputAudioPort(.speaker)
        }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// `AVAudioPlayerDelegate` 需 NSObject；用轻量中继收尾。
private final class PlayerFinishRelay: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
