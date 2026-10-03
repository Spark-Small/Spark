//
//  APIEndpoint+ActivitiesWrite.swift
//  坐标系
//
//  活动写 API 契约（后端就绪后接线；当前 Domain UC + 本地快照为真相源）。
//

import CoordinateModels
import CoordinateNetworking
import Foundation

struct ActivityJoinRequest: Encodable, Sendable {
    var activityID: UUID
}

struct ActivityPublishRequest: Encodable, Sendable {
    var title: String
    var category: ActivityCategory
    var location: String
    var date: Date
    var capacity: Int
    var fee: String
    var summary: String
    var tags: [String]
    var latitude: Double?
    var longitude: Double?
}

struct ActivityRescheduleRequest: Encodable, Sendable {
    var date: Date
    var note: String?
}

struct ActivityCapacityRequest: Encodable, Sendable {
    var capacity: Int
}

/// 空 JSON 对象响应 / 请求体占位。
struct EmptyJSONBody: Codable, Sendable {}

extension APIEndpoint where Response == Activity {
    static func joinActivity(id: UUID) throws -> APIEndpoint<Activity> {
        APIEndpoint(
            path: "activities/\(id.uuidString.lowercased())/join",
            method: .post,
            body: try JSONEncoder().encode(ActivityJoinRequest(activityID: id))
        )
    }

    static func leaveActivity(id: UUID) throws -> APIEndpoint<Activity> {
        APIEndpoint(
            path: "activities/\(id.uuidString.lowercased())/leave",
            method: .post,
            body: try JSONEncoder().encode(EmptyJSONBody())
        )
    }

    static func publishActivity(_ body: ActivityPublishRequest) throws -> APIEndpoint<Activity> {
        APIEndpoint(
            path: "activities",
            method: .post,
            body: try JSONEncoder().encode(body)
        )
    }

    static func updateActivity(id: UUID, _ body: ActivityPublishRequest) throws -> APIEndpoint<Activity> {
        APIEndpoint(
            path: "activities/\(id.uuidString.lowercased())",
            method: .put,
            body: try JSONEncoder().encode(body)
        )
    }
}

extension APIEndpoint where Response == EmptyJSONBody {
    static func cancelActivity(id: UUID) -> APIEndpoint<EmptyJSONBody> {
        APIEndpoint(
            path: "activities/\(id.uuidString.lowercased())",
            method: .delete
        )
    }

    static func rescheduleActivity(id: UUID, date: Date, note: String?) throws -> APIEndpoint<EmptyJSONBody> {
        APIEndpoint(
            path: "activities/\(id.uuidString.lowercased())/reschedule",
            method: .post,
            body: try JSONEncoder().encode(ActivityRescheduleRequest(date: date, note: note))
        )
    }

    static func updateActivityCapacity(id: UUID, capacity: Int) throws -> APIEndpoint<EmptyJSONBody> {
        APIEndpoint(
            path: "activities/\(id.uuidString.lowercased())/capacity",
            method: .post,
            body: try JSONEncoder().encode(ActivityCapacityRequest(capacity: capacity))
        )
    }
}
