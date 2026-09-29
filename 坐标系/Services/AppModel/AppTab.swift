//
//  AppTab.swift
//  坐标系
//

import Foundation
import CoordinateModels

enum AppTab: Hashable {
    case activities
    case buddies
    case community
    case messages
    case profile

    var analyticsKey: String {
        switch self {
        case .activities: "activities"
        case .buddies: "buddies"
        case .community: "community"
        case .messages: "messages"
        case .profile: "profile"
        }
    }
}
