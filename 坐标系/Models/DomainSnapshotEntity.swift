//
//  DomainSnapshotEntity.swift
//  坐标系
//
//  SwiftData：五域快照统一实体（每域一行，payload 为 Codable 编码）。
//

import Foundation
import SwiftData

@Model
final class DomainSnapshotEntity {
    @Attribute(.unique) var domainKey: String
    var payload: Data
    var updatedAt: Date

    init(domainKey: String, payload: Data, updatedAt: Date = .now) {
        self.domainKey = domainKey
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

enum SnapshotDomainKey {
    static let activities = "activities"
    static let messages = "messages"
    static let buddies = "buddies"
    static let community = "community"
    static let profile = "profile"
    static let engagement = "engagement"
}
