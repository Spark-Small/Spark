//
//  RefundFlow+Processing.swift
//  坐标系
//
//  退款异步处理、到账与持久化。
//

import CoordinateFeatureFlags
import CoordinateModels
import Foundation

extension RefundFlowService {

    func insert(_ record: RefundRequestRecord) {
        requests.insert(record, at: 0)
        persist()
    }

    func update(_ record: RefundRequestRecord) {
        guard let index = requests.firstIndex(where: { $0.id == record.id }) else { return }
        requests[index] = record
        persist()
    }

    func enqueueProcessing(
        recordID: UUID,
        expedited: Bool,
        onActivityCancelled: @escaping () -> Void
    ) {
        // 远程钱包：只提交退款案，完结等服务端；禁止本地秒退入账。
        if FeatureFlags.useRemoteWallet {
            processingTasks[recordID]?.cancel()
            processingTasks[recordID] = Task { @MainActor in
                guard var record = request(id: recordID) else { return }
                let orderType = record.kind == .activity ? "activity" : "booking"
                do {
                    let remote = try await RemoteWalletClient.submitRefund(
                        orderType: orderType,
                        orderID: record.orderID,
                        amountCents: record.amountCents,
                        reason: record.reason
                    )
                    record.status = .processing
                    record.processingStartedAt = .now
                    update(record)
                    CommerceAnalytics.refundSubmit(orderType: orderType, result: "submitted")
                    if remote.status == "completed" || remote.status == "refunded" {
                        finalize(recordID: recordID, onActivityCancelled: onActivityCancelled)
                    }
                } catch {
                    CommerceAnalytics.refundSubmit(orderType: orderType, result: "failed")
                    // 保持已提交，披露等服务端；不本地假完结
                }
                processingTasks[recordID] = nil
            }
            return
        }

        // Release：不本地 sleep 完结；保持「已提交」，等服务端回调 / 运营审核。
        guard CommercePaymentPolicy.simulatesLocalRefundCompletion else {
            processingTasks[recordID] = nil
            CommerceAnalytics.refundSubmit(orderType: "local", result: "pending_server")
            return
        }
        processingTasks[recordID]?.cancel()
        processingTasks[recordID] = Task { @MainActor in
            let delay: Duration = expedited ? .milliseconds(350) : .milliseconds(900)
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }

            guard var record = request(id: recordID) else { return }
            record.status = .processing
            record.processingStartedAt = .now
            update(record)

            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }

            finalize(recordID: recordID, onActivityCancelled: onActivityCancelled)
            processingTasks[recordID] = nil
        }
    }

    func finalize(
        recordID: UUID,
        onActivityCancelled: @escaping () -> Void
    ) {
        guard var record = request(id: recordID) else { return }
        guard record.status == .processing || record.status == .submitted else { return }

        switch record.kind {
        case .activity:
            finalizeActivity(&record, onActivityCancelled: onActivityCancelled)
        case .booking:
            finalizeBooking(&record)
        }

        record.status = .completed
        record.completedAt = .now
        update(record)
    }

    func finalizeActivity(
        _ record: inout RefundRequestRecord,
        onActivityCancelled: () -> Void
    ) {
        ActivityPaymentStore.finalizeRefund(orderID: record.orderID)
        trustService.record(
            .activityRefunded,
            domain: .activity,
            actorKey: trustActorKey(),
            subjectKey: record.subjectTitle,
            note: record.reason
        )
        if record.cancelsRegistration {
            onActivityCancelled()
        }
    }

    func finalizeBooking(_ record: inout RefundRequestRecord) {
        let method = PaymentMethod.resolve(record.paymentMethod)
        walletStore.credit(
            amountCents: record.amountCents,
            method: method,
            kind: .bookingRefund,
            title: "陪玩退款 · \(record.subjectTitle)",
            subtitle: record.amountDisplay,
            relatedID: record.orderID
        )
        NotificationService.cancelBookingReminder(bookingID: record.orderID)
        NotificationService.scheduleBookingRefundCompletedNotification(
            bookingID: record.orderID,
            companion: record.subjectTitle,
            amountDisplay: record.amountDisplay
        )
        walletPassStore.void(relatedID: record.orderID)
        trustService.record(
            .bookingRefunded,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: record.subjectTitle,
            note: record.reason
        )
        bookingFinalizeHandlers[record.id]?(record.orderID)
        bookingFinalizeHandlers.removeValue(forKey: record.id)
        bookingRejectHandlers.removeValue(forKey: record.id)
    }

    func trustActorKey() -> String {
        LocalUserIdentity.current.uuidString
    }

    static func loadAll() -> [RefundRequestRecord] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([RefundRequestRecord].self, from: data)
        else { return [] }
        return decoded
    }

    func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.fileName)
        do {
            let data = try JSONEncoder().encode(requests)
            try data.write(to: url, options: [.atomic])
        } catch {
            assertionFailure("RefundFlow persist failed: \(error)")
            PersistenceWriteFailureReporter.record(domainKey: "refunds", error: error)
        }
    }
}
