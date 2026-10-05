//
//  RefundModels.swift
//  坐标系
//
//  退款请求模型与提交错误。
//

import Foundation
import CoordinateModels

enum RefundRequestKind: String, Codable, Hashable {
    case activity
    case booking
}

enum RefundRequestStatus: String, Codable, Hashable, CaseIterable {
    case submitted
    case processing
    case completed
    case rejected

    var label: String {
        switch self {
        case .submitted: "已提交"
        case .processing: "处理中"
        case .completed: "已完成"
        case .rejected: "已拒绝"
        }
    }
}

enum RefundInitiator: String, Codable, Hashable {
    case user
    case system
}

struct RefundRequestRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: RefundRequestKind
    /// 关联 ActivityOrder.id 或 BuddyBookingRecord.id
    let orderID: UUID
    let subjectTitle: String
    let amountCents: Int
    let amountDisplay: String
    let paymentMethod: String
    var reason: String
    var detail: String
    var status: RefundRequestStatus
    let initiator: RefundInitiator
    let createdAt: Date
    var processingStartedAt: Date?
    var completedAt: Date?
    /// 活动退款完成后是否取消参加
    var cancelsRegistration: Bool
    var activityID: UUID?
    var rejectionMessage: String?
}

enum RefundSubmitError: LocalizedError {
    case policyDenied(String)
    case orderNotRefundable
    case duplicateInFlight
    case orderNotFound
    case bookingNotFound

    var errorDescription: String? {
        switch self {
        case .policyDenied(let message): message
        case .orderNotRefundable: "当前订单不可退款"
        case .duplicateInFlight: "该订单已有退款申请在处理中"
        case .orderNotFound: "订单不存在"
        case .bookingNotFound: "预约不存在"
        }
    }
}

