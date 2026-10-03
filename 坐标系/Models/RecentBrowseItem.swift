//
//  RecentBrowseItem.swift
//  坐标系
//
//  SwiftData V2：跨 Tab 最近浏览（活动 / 搭子 / 陪玩 / 俱乐部；无广场）。
//

import CoordinateModels
import Foundation
import SwiftData

@Model
final class RecentBrowseItem {
    /// `kindRaw|targetID` 唯一键。
    @Attribute(.unique) var recordKey: String
    var kindRaw: String
    var targetID: UUID
    var title: String
    var subtitle: String
    var viewedAt: Date

    init(
        kind: RecentBrowseKind,
        targetID: UUID,
        title: String,
        subtitle: String = "",
        viewedAt: Date = .now
    ) {
        self.recordKey = Self.makeRecordKey(kind: kind, targetID: targetID)
        self.kindRaw = kind.rawValue
        self.targetID = targetID
        self.title = title
        self.subtitle = subtitle
        self.viewedAt = viewedAt
    }

    var kind: RecentBrowseKind {
        RecentBrowseKind(rawValue: kindRaw) ?? .activity
    }

    var asRecord: RecentBrowseRecord {
        RecentBrowseRecord(
            kind: kind,
            targetID: targetID,
            title: title,
            subtitle: subtitle,
            viewedAt: viewedAt
        )
    }

    static func makeRecordKey(kind: RecentBrowseKind, targetID: UUID) -> String {
        "\(kind.rawValue)|\(targetID.uuidString)"
    }
}
