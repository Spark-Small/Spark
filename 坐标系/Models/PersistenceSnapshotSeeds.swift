//
//  PersistenceSnapshotSeeds.swift
//  坐标系
//
//  冷启动 / 解码失败回退种子。Release 不注入「已参加 / 已预约」等虚构用户态（审核 2.3.1）。
//

import Foundation
import CoordinateModels

extension ActivitiesSnapshot {
    static var seed: ActivitiesSnapshot {
        #if DEBUG
        ActivitiesSnapshot(
            activities: SampleData.activities,
            joinedIDs: [
                SampleData.activities[1].id,
                SampleData.activities[6].id,
                SampleData.activities[8].id,
                SampleData.activities[9].id,
                SampleData.demoJourneyActivityID
            ],
            favoriteIDs: [SampleData.activities[3].id],
            waitlistIDs: [SampleData.activities[10].id],
            waitlistSpotNotifiedIDs: []
        )
        #else
        // Release：可浏览目录，但不静默报名 / 收藏 / 候补。
        ActivitiesSnapshot(
            activities: SampleData.activities,
            joinedIDs: [],
            favoriteIDs: [],
            waitlistIDs: [],
            waitlistSpotNotifiedIDs: []
        )
        #endif
    }
}

extension MessagesSnapshot {
    static var seed: MessagesSnapshot {
        #if DEBUG
        let conversations = SampleData.conversations
        var threads: [String: [ChatMessage]] = [:]
        for conversation in conversations {
            threads[conversation.id.uuidString] = SampleData.messages(for: conversation.id)
        }
        return MessagesSnapshot(
            conversations: conversations,
            threads: threads,
            friendRequests: SampleData.friendRequests
        )
        #else
        MessagesSnapshot(conversations: [], threads: [:], friendRequests: [])
        #endif
    }
}

extension ProfileSnapshot {
    static var seed: ProfileSnapshot {
        ProfileSnapshot(
            user: SampleData.currentUser,
            hasCompletedOnboarding: false,
            blockedUserNames: [],
            followedUserNames: [],
            moderationTickets: []
        )
    }
}

extension BuddiesSnapshot {
    static var seed: BuddiesSnapshot {
        #if DEBUG
        let joinedIDs = Array(SampleData.joinedSeedCircleIDs)
        return BuddiesSnapshot(
            inviteRecords: SampleData.seedInviteRecords,
            bookingRecords: SampleData.seedBookingRecords,
            clubs: [],
            joinedCircleIDs: joinedIDs,
            joinedCircleNames: SampleData.interestCircles
                .filter { SampleData.joinedSeedCircleIDs.contains($0.id) }
                .map(\.name),
            joinedGuildNames: SampleData.companionGuilds.filter(\.isJoined).map(\.name),
            membershipPrefs: [:]
        )
        #else
        BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            clubs: [],
            joinedCircleIDs: [],
            joinedCircleNames: [],
            joinedGuildNames: [],
            membershipPrefs: [:]
        )
        #endif
    }
}

extension ActivityEngagementSnapshot {
    static let seed = ActivityEngagementSnapshot(
        tagWeights: [:],
        categoryWeights: [:],
        lastDecayAt: .now
    )
}

extension ProfileRecentBrowseSnapshot {
    static let seed = ProfileRecentBrowseSnapshot(items: [])
}

extension CommunitySnapshot {
    /// 社区冷启动回退。命名历史原因仍叫 emptySeed；Release 帖子为空。
    static var emptySeed: CommunitySnapshot {
        #if DEBUG
        CommunitySnapshot(
            posts: SampleData.posts,
            likedIDs: [],
            repostedIDs: [],
            bookmarkedIDs: [],
            bookmarkCollections: [:],
            reportedIDs: [],
            likedCommentIDs: []
        )
        #else
        CommunitySnapshot(
            posts: [],
            likedIDs: [],
            repostedIDs: [],
            bookmarkedIDs: [],
            bookmarkCollections: [:],
            reportedIDs: [],
            likedCommentIDs: []
        )
        #endif
    }
}
