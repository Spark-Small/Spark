//
//  APIEndpoint+BuddiesWrite.swift
//  坐标系
//
//  搭子写 API 契约（邀约 / 俱乐部）；默认未开 `useRemoteBuddiesWrite`。
//  本地 Snapshot 仍为真相源；接通后经 RemoteInviteSync / RemoteClubSync 提交，禁止假成功。
//

import CoordinateModels
import CoordinateNetworking
import Foundation

struct BuddyInviteSubmitRequest: Encodable, Sendable {
    var id: UUID
    var nickname: String
    var inviteeUserID: UUID?
    var activityTitle: String
    var relatedActivityID: UUID?
    var sentAt: Date
}

struct BuddyClubCreateRequest: Encodable, Sendable {
    var id: UUID
    var name: String
    var topic: String
    var city: String
    var tags: [String]
    var summary: String
    var systemImage: String
    var creatorName: String
    var creatorUserID: UUID?
}

struct BuddyClubMembershipRequest: Encodable, Sendable {
    var circleID: UUID
}

extension APIEndpoint where Response == BuddyInviteRecord {
    static func submitInvite(_ request: BuddyInviteSubmitRequest) throws -> APIEndpoint<BuddyInviteRecord> {
        APIEndpoint(
            path: "buddies/invites",
            method: .post,
            body: try JSONEncoder().encode(request)
        )
    }
}

extension APIEndpoint where Response == InterestCircle {
    static func createClub(_ request: BuddyClubCreateRequest) throws -> APIEndpoint<InterestCircle> {
        APIEndpoint(
            path: "buddies/clubs",
            method: .post,
            body: try JSONEncoder().encode(request)
        )
    }
}

extension APIEndpoint where Response == EmptyJSONBody {
    static func joinClub(id: UUID) throws -> APIEndpoint<EmptyJSONBody> {
        APIEndpoint(
            path: "buddies/clubs/\(id.uuidString.lowercased())/join",
            method: .post,
            body: try JSONEncoder().encode(BuddyClubMembershipRequest(circleID: id))
        )
    }

    static func leaveClub(id: UUID) throws -> APIEndpoint<EmptyJSONBody> {
        APIEndpoint(
            path: "buddies/clubs/\(id.uuidString.lowercased())/leave",
            method: .post,
            body: try JSONEncoder().encode(BuddyClubMembershipRequest(circleID: id))
        )
    }
}
