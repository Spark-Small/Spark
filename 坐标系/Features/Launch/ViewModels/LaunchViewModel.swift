//
//  LaunchViewModel.swift
//  坐标系
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class LaunchViewModel {
    var state: LaunchState = .brandSplash
    private(set) var isInteractionLocked = false
    private var didFinishBrandSplash = false

    func brandSplashFinished(reduceMotion: Bool) {
        guard state == .brandSplash, !didFinishBrandSplash else { return }
        didFinishBrandSplash = true

        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.22)) {
                state = .invitationReady
            }
            return
        }

        withAnimation(LaunchMotion.logoDissolve) {
            state = .brandTransition
        }

        Task {
            try? await Task.sleep(for: .milliseconds(520))
            withAnimation(LaunchMotion.envelopeArrive) {
                state = .invitationReady
            }
        }
    }

    func openInvitation(reduceMotion: Bool) {
        guard state == .invitationReady, !isInteractionLocked else { return }
        isInteractionLocked = true

        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.28)) {
                state = .login
            }
            return
        }

        withAnimation(LaunchMotion.flapOpen) {
            state = .opening
        }
    }

    func envelopeOpenFinished() {
        guard state == .opening else { return }

        withAnimation(LaunchMotion.paperUnfold) {
            state = .letterExpanding
        }

        Task {
            try? await Task.sleep(for: LaunchMotion.expandSequence)
            withAnimation(LaunchMotion.stateCrossfade) {
                state = .login
            }
        }
    }
}
