//
//  LoginLoopingVideoBackground.swift
//  坐标系
//
//  登录背景：AVQueuePlayer + AVPlayerLooper 静音循环；Reduce Motion / 无片源回退分组底。
//

import AVFoundation
import SwiftUI
import UIKit

enum LoginBackgroundVideoResource {
    static let resourceName = "LoginBackground"

    /// 设备 Bundle 区分扩展名大小写；优先小写。
    static var bundleURL: URL? {
        let bundle = Bundle.main
        for ext in ["mp4", "MP4", "mov", "MOV"] {
            if let url = bundle.url(forResource: resourceName, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

struct LoginBackgroundChrome: View {
    var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)

            if let url = LoginBackgroundVideoResource.bundleURL, !reduceMotion {
                LoginLoopingVideoBackground(url: url, isActive: isActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
    }
}

struct LoginLoopingVideoBackground: UIViewRepresentable {
    let url: URL
    var isActive: Bool

    func makeUIView(context: Context) -> LoginLoopingPlayerUIView {
        let view = LoginLoopingPlayerUIView()
        for axis: NSLayoutConstraint.Axis in [.horizontal, .vertical] {
            view.setContentHuggingPriority(.defaultLow, for: axis)
            view.setContentCompressionResistancePriority(.defaultLow, for: axis)
        }
        view.configure(url: url)
        view.setActive(isActive)
        return view
    }

    func updateUIView(_ uiView: LoginLoopingPlayerUIView, context: Context) {
        uiView.configure(url: url)
        uiView.setActive(isActive)
    }

    static func dismantleUIView(_ uiView: LoginLoopingPlayerUIView, coordinator: ()) {
        uiView.teardown()
    }
}

final class LoginLoopingPlayerUIView: UIView {
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private let playerLayer = AVPlayerLayer()
    private var configuredURL: URL?
    private var wantsPlayback = false
    private var didRegisterLifecycleObservers = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        backgroundColor = .clear
        clipsToBounds = true
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyPlaybackState()
    }

    func configure(url: URL) {
        guard configuredURL != url else { return }
        let shouldResume = wantsPlayback
        releasePlayer()
        configuredURL = url

        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = true
        queue.automaticallyWaitsToMinimizeStalling = true
        queue.allowsExternalPlayback = false

        playerLooper = AVPlayerLooper(player: queue, templateItem: item)
        queuePlayer = queue
        playerLayer.player = queue

        wantsPlayback = shouldResume
        registerLifecycleObserversIfNeeded()
        applyPlaybackState()
    }

    func setActive(_ active: Bool) {
        wantsPlayback = active
        applyPlaybackState()
    }

    /// 卸下播放器并清空播放意图（视图拆除时调用）。
    func teardown() {
        wantsPlayback = false
        releasePlayer()
    }

    private func releasePlayer() {
        queuePlayer?.pause()
        playerLayer.player = nil
        playerLooper = nil
        queuePlayer = nil
        configuredURL = nil
    }

    private func applyPlaybackState() {
        guard queuePlayer != nil else { return }
        if wantsPlayback, window != nil {
            queuePlayer?.play()
        } else {
            queuePlayer?.pause()
        }
    }

    private func registerLifecycleObserversIfNeeded() {
        guard !didRegisterLifecycleObservers else { return }
        didRegisterLifecycleObservers = true
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func handleDidEnterBackground() {
        queuePlayer?.pause()
    }

    @objc private func handleWillEnterForeground() {
        applyPlaybackState()
    }
}
