//
//  RecentBrowseItem.swift
//  坐标系
//
//  SwiftData：最近浏览活动（替代 profile_recent_browse.json）。
//

import CoordinateModels
import Foundation
import SwiftData

@Model
final class RecentBrowseItem {
    @Attribute(.unique) var activityID: UUID
    var title: String
    var viewedAt: Date

    init(activityID: UUID, title: String, viewedAt: Date = .now) {
        self.activityID = activityID
        self.title = title
        self.viewedAt = viewedAt
    }

    var asRecord: ProfileRecentBrowseRecord {
        ProfileRecentBrowseRecord(
            activityID: activityID,
            title: title,
            viewedAt: viewedAt
        )
    }
}
