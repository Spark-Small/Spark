//
//  ActivityTicketNumber.swift
//  坐标系
//
//  活动票面票号：与订单 / Pass serial 同源，紧凑展示。
//

import Foundation
import CoordinateModels

@MainActor
enum ActivityTicketNumber {
    /// 票号源 ID：优先付费订单，其次任意展示订单，否则活动 ID（免费参加票）。
    static func sourceID(for activity: Activity) -> UUID {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            return order.id
        }
        if let order = ActivityPaymentStore.displayOrder(for: activity.id) {
            return order.id
        }
        return activity.id
    }

    /// 票面展示：`D0000000-000000000013`（UUID 首段 + 末段，与演示订单同族）。
    static func display(for activity: Activity) -> String {
        format(sourceID(for: activity))
    }

    static func format(_ id: UUID) -> String {
        let parts = id.uuidString.uppercased().split(separator: "-")
        guard parts.count == 5 else {
            return id.uuidString.uppercased()
        }
        return "\(parts[0])-\(parts[4])"
    }
}
