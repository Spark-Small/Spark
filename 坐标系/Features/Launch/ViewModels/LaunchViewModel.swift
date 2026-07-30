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
    var state: LaunchState = .invitationReady
    private(set) var isInteractionLocked = false

    func openInvitation(reduceMotion: Bool) {
        guard state == .invitationReady, !isInteractionLocked else { return }
        isInteractionLocked = true

        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : LaunchMotion.flapOpen) {
            state = .opening
        }
    }

    func envelopeOpenFinished() {
        guard state == .opening else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            state = .invitationOpened
        }
    }
}
