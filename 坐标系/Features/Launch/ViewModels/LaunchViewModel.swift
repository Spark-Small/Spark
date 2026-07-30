//
//  LaunchViewModel.swift
//  坐标系
//

import Observation
import SwiftUI

@MainActor
@Observable
final class LaunchViewModel {
    var state: LaunchState = .invitationReady

    func openInvitation(reduceMotion: Bool) {
        guard state == .invitationReady else { return }

        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : LaunchMotion.flapOpen) {
            state = .opening
        }
    }

    /// 信纸升起完成后调用：停留片刻，再自动切入登录。
    func envelopeOpenFinished(reduceMotion: Bool) {
        guard state == .opening else { return }
        state = .invitationOpened

        Task { @MainActor in
            try? await Task.sleep(
                for: reduceMotion ? .milliseconds(120) : LaunchMotion.letterDwell
            )
            guard state == .invitationOpened else { return }
            state = .login
        }
    }
}
