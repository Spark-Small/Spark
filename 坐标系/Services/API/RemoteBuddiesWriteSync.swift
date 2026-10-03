//
//  RemoteBuddiesWriteSync.swift
//  坐标系
//
//  搭子写路径远程同步缝：邀约 / 俱乐部。默认 Disabled；开 `useRemoteBuddiesWrite` 后才发请求。
//  失败保留本机记录，禁止 Toast 伪装「对方已收到」。
//

import CoordinateFeatureFlags
import CoordinateModels
import CoordinateNetworking
import Foundation

protocol RemoteInviteSyncing: Sendable {
    var isEnabled: Bool { get }
    func submit(_ record: BuddyInviteRecord) async throws -> BuddyInviteRecord
}

protocol RemoteClubSyncing: Sendable {
    var isEnabled: Bool { get }
    func create(_ club: InterestCircle, creatorUserID: UUID?) async throws -> InterestCircle
    func join(circleID: UUID) async throws
    func leave(circleID: UUID) async throws
}

struct DisabledRemoteInviteSync: RemoteInviteSyncing {
    var isEnabled: Bool { false }

    func submit(_ record: BuddyInviteRecord) async throws -> BuddyInviteRecord {
        record
    }
}

struct DisabledRemoteClubSync: RemoteClubSyncing {
    var isEnabled: Bool { false }

    func create(_ club: InterestCircle, creatorUserID: UUID?) async throws -> InterestCircle {
        club
    }

    func join(circleID: UUID) async throws {}

    func leave(circleID: UUID) async throws {}
}

struct RemoteInviteSyncService: RemoteInviteSyncing {
    let client: APIClient

    var isEnabled: Bool { FeatureFlags.useRemoteBuddiesWrite }

    func submit(_ record: BuddyInviteRecord) async throws -> BuddyInviteRecord {
        let request = BuddyInviteSubmitRequest(
            id: record.id,
            nickname: record.nickname,
            inviteeUserID: record.inviteeUserID,
            activityTitle: record.activityTitle,
            relatedActivityID: record.relatedActivityID,
            sentAt: record.sentAt
        )
        return try await client.send(try .submitInvite(request))
    }
}

struct RemoteClubSyncService: RemoteClubSyncing {
    let client: APIClient

    var isEnabled: Bool { FeatureFlags.useRemoteBuddiesWrite }

    func create(_ club: InterestCircle, creatorUserID: UUID?) async throws -> InterestCircle {
        let request = BuddyClubCreateRequest(
            id: club.id,
            name: club.name,
            topic: club.topic,
            city: club.city,
            tags: club.tags,
            summary: club.summary,
            systemImage: club.systemImage,
            creatorName: club.creatorName,
            creatorUserID: creatorUserID
        )
        return try await client.send(try .createClub(request))
    }

    func join(circleID: UUID) async throws {
        _ = try await client.send(try .joinClub(id: circleID))
    }

    func leave(circleID: UUID) async throws {
        _ = try await client.send(try .leaveClub(id: circleID))
    }
}
