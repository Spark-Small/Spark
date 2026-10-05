//
//  ProfileMeetRadius.swift
//  CoordinateModels
//
//  出行半径：同城 / 可跨城 / 仅线上先聊。
//

import Foundation

public enum ProfileMeetRadius: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case sameCity = "同城见面"
    case crossCity = "可跨城"
    case chatFirst = "仅线上先聊"

    public var id: String { rawValue }
}
