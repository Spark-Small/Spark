//
//  CommunityEngagementNotificationKeys.swift
//  CoordinateDomain
//
//  站内社区通知 dedupeKey 约定（Feature 写回 InAppNotificationStore 时共用）。
//

import Foundation

public enum CommunityEngagementNotificationKeys: Sendable {
    /// `community-{kind}-{postID}-{actorName}`。同 actor 对同帖同 kind：写入幂等、取消互动按此键撤销。
    public static func dedupeKey(kind: String, postID: UUID, actorName: String) -> String {
        "community-\(kind)-\(postID.uuidString)-\(actorName)"
    }
}
