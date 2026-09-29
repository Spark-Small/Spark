//
//  APIEndpoint+Snapshots.swift
//  坐标系
//
//  五域快照端点（依赖 App 内 Snapshot 类型）。
//

import CoordinateNetworking
import Foundation
import CoordinateModels

extension APIEndpoint where Response == ActivitiesSnapshot {
    static var activitiesCatalog: APIEndpoint<ActivitiesSnapshot> {
        APIEndpoint(path: "activities/catalog")
    }
}

extension APIEndpoint where Response == ProfileSnapshot {
    static var profileSnapshot: APIEndpoint<ProfileSnapshot> {
        APIEndpoint(path: "profile")
    }
}

extension APIEndpoint where Response == MessagesSnapshot {
    static var messagesSnapshot: APIEndpoint<MessagesSnapshot> {
        APIEndpoint(path: "messages/snapshot")
    }
}

extension APIEndpoint where Response == CommunitySnapshot {
    static var communitySnapshot: APIEndpoint<CommunitySnapshot> {
        APIEndpoint(path: "community/snapshot")
    }
}

extension APIEndpoint where Response == BuddiesSnapshot {
    static var buddiesSnapshot: APIEndpoint<BuddiesSnapshot> {
        APIEndpoint(path: "buddies/snapshot")
    }
}
