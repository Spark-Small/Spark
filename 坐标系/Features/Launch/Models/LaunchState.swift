//
//  LaunchState.swift
//  坐标系
//

import Foundation

enum LaunchState: Int, Equatable, Hashable, CaseIterable, Sendable {
    case brandSplash
    case brandTransition
    case invitationReady
    case opening
    case letterExpanding
    case login
}
