//
//  PersistenceBoundary.swift
//  坐标系
//
//  持久化边界：哪些域走 SwiftData、哪些保持 JSON / UserDefaults。
//  与 Apple 推荐一致——关系型 UI 数据用 @Model；交易流水 / 偏好用专用 Store。
//

import Foundation

/// 存储后端类型（架构决策表，非运行时多态）。
enum PersistenceBackend: String, Sendable, CaseIterable {
    /// `DomainSnapshotEntity` 单行 JSON blob（五域 + engagement）
    case swiftDataSnapshotBlob
    /// 原生 `@Model` 实体（可 `@Query`）
    case swiftDataEntity
    /// App 沙盒 JSON 文件（商业流水、审计类）
    case jsonFile
    /// `UserDefaults` / 轻量偏好
    case userDefaults
}

/// 产品域持久化策略（代码即文档）。
enum PersistenceDomain: String, Sendable, CaseIterable {
    case activities
    case messages
    case buddies
    case community
    case profile
    case engagement
    case recentBrowse
    case activityOrders
    case walletPasses
    case refundRequests
    case trustBehavior
    case membership
    case notificationPreferences
    case privacyPreferences
    case legalConsent

    var backend: PersistenceBackend {
        switch self {
        case .activities, .messages, .buddies, .community, .profile, .engagement:
            return .swiftDataSnapshotBlob
        case .recentBrowse:
            return .swiftDataEntity
        case .activityOrders, .walletPasses, .refundRequests, .trustBehavior:
            return .jsonFile
        case .membership, .notificationPreferences, .privacyPreferences, .legalConsent:
            return .userDefaults
        }
    }

    /// 是否计划拆成细粒度 `@Model`（非 blob）。商业 JSON 域明确为 `false`。
    var migratesToGranularSwiftData: Bool {
        switch self {
        case .recentBrowse:
            return true
        case .activityOrders, .walletPasses, .refundRequests, .trustBehavior:
            return false
        case .activities, .messages, .buddies, .community, .profile, .engagement:
            return true
        default:
            return false
        }
    }

    var legacyJSONFileName: String? {
        switch self {
        case .activities: "activities_snapshot.json"
        case .messages: "messages_snapshot.json"
        case .buddies: "buddies_snapshot.json"
        case .community: "community_snapshot.json"
        case .profile: "profile_snapshot.json"
        case .engagement: "activity_engagement_snapshot.json"
        case .recentBrowse: "profile_recent_browse.json"
        case .activityOrders: "activity_orders.json"
        case .walletPasses: "wallet_passes.json"
        case .refundRequests: "refund_requests.json"
        case .trustBehavior: "trust_behavior_events.json"
        default: nil
        }
    }
}
