//
//  RefundFlow.swift
//  坐标系
//
//  统一退款申请、异步处理与到账闭环（活动 / 陪玩）。
//

import CoordinateFeatureFlags
import CoordinateModels
import Foundation
import Observation

@MainActor
@Observable
final class RefundFlowService {
    static var shared: RefundFlowService { AppComposition.refundFlowService }

    let walletStore: WalletStore
    let walletPassStore: WalletPassStore
    let trustService: TrustService

    static let fileName = "refund_requests.json"
    /// 跨文件扩展（`+Processing`）会写入，故非 `private(set)`。
    var requests: [RefundRequestRecord] = []
    var processingTasks: [UUID: Task<Void, Never>] = [:]
    var bookingFinalizeHandlers: [UUID: (BuddyBookingRecord.ID) -> Void] = [:]
    var bookingRejectHandlers: [UUID: (BuddyBookingRecord.ID) -> Void] = [:]

    init(
        walletStore: WalletStore,
        walletPassStore: WalletPassStore,
        trustService: TrustService
    ) {
        self.walletStore = walletStore
        self.walletPassStore = walletPassStore
        self.trustService = trustService
        requests = Self.loadAll().sorted { $0.createdAt > $1.createdAt }
    }

    func request(id: UUID) -> RefundRequestRecord? {
        requests.first { $0.id == id }
    }

    func latestRequest(forOrderID orderID: UUID) -> RefundRequestRecord? {
        requests.first { $0.orderID == orderID }
    }

    func isRefunding(orderID: UUID) -> Bool {
        guard let record = latestRequest(forOrderID: orderID) else { return false }
        return record.status == .submitted || record.status == .processing
    }

    func rejectRequest(
        requestID: UUID,
        message: String = RefundFlowCopy.rejectedHint
    ) {
        guard var record = request(id: requestID) else { return }
        guard record.status == .submitted || record.status == .processing else { return }
        processingTasks[requestID]?.cancel()
        processingTasks.removeValue(forKey: requestID)
        record.status = .rejected
        record.rejectionMessage = message
        record.completedAt = .now
        update(record)
        if record.kind == .booking {
            bookingRejectHandlers[requestID]?(record.orderID)
            bookingRejectHandlers.removeValue(forKey: requestID)
            bookingFinalizeHandlers.removeValue(forKey: requestID)
        }
    }

    func resetAll() {
        processingTasks.values.forEach { $0.cancel() }
        processingTasks.removeAll()
        bookingFinalizeHandlers.removeAll()
        bookingRejectHandlers.removeAll()
        requests = []
        persist()
    }
}

