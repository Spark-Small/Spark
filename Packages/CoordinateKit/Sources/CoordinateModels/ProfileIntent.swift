//
//  ProfileIntent.swift
//  CoordinateModels
//
//  「我想怎么玩」意图 chips（替代遗留 lookingFor 编辑写入）。
//

import Foundation

public enum ProfileIntent: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case findPeers = "找同好"
    case joinActivities = "组局参加"
    case chatFirst = "只聊天先熟悉"
    case bookCompanion = "约陪玩服务"
    case buildClub = "建俱乐部"

    public var id: String { rawValue }
}

public enum ProfileIntentLimits {
    /// 对外多选上限
    public static let maxSelected = 2

    public static func clamped(_ intents: [ProfileIntent]) -> [ProfileIntent] {
        var seen = Set<ProfileIntent>()
        var result: [ProfileIntent] = []
        for intent in intents where seen.insert(intent).inserted {
            result.append(intent)
            if result.count >= maxSelected { break }
        }
        return result
    }

    /// 展示行：优先意图 chips；否则回落遗留 lookingFor 文案。
    public static func displayLine(intents: [ProfileIntent], legacyLookingFor: String) -> String {
        let clamped = Self.clamped(intents)
        if !clamped.isEmpty {
            return clamped.map(\.rawValue).joined(separator: " · ")
        }
        return legacyLookingFor.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
