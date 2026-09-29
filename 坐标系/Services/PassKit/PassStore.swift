//
//  PassStore.swift
//  坐标系
//
//  通行证权威存储：issue / update / void；对接 Source、分发与更新 Web Service。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class PassStore {
    static var shared: PassStore { AppComposition.walletPassStore }

    private static let fileName = "wallet_passes.json"
    private(set) var passes: [PassRecord]

    init() {
        passes = Self.load().sorted { $0.createdAt > $1.createdAt }
        PassConfiguration.ensureDirectories()
    }

    func pass(id: UUID) -> PassRecord? {
        passes.first { $0.id == id }
    }

    func pass(relatedID: UUID) -> PassRecord? {
        passes.first { $0.relatedID == relatedID }
    }

    func pass(serialNumber: String) -> PassRecord? {
        passes.first { $0.serialNumber == serialNumber }
    }

    /// 未作废的关联通行证。
    func activePass(relatedID: UUID) -> PassRecord? {
        passes.first { $0.relatedID == relatedID && !$0.voided }
    }

    /// 活动当前对外凭证：付费只认订单票；免费认参加票。
    /// - Parameter activeOnly: true 时忽略已作废。
    func activityPass(for activity: Activity, activeOnly: Bool = true) -> PassRecord? {
        let related: UUID
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            related = order.id
        } else {
            related = activity.id
        }
        if activeOnly {
            return activePass(relatedID: related)
        }
        return activePass(relatedID: related) ?? pass(relatedID: related)
    }

    /// 票面展示用：作废态取任意记录；否则优先有效，回退任意。
    func resolvedActivityPass(for activity: Activity, voided: Bool = false) -> PassRecord? {
        if voided {
            return activityPass(for: activity, activeOnly: false)
        }
        return activityPass(for: activity, activeOnly: true)
            ?? activityPass(for: activity, activeOnly: false)
    }

    /// 预览轨：有有效凭证，或尚未签发但业务关系仍在（参加/主办）。
    func shouldShowActivityOnPreviewRail(
        _ activity: Activity,
        isJoined: Bool,
        isHost: Bool
    ) -> Bool {
        if activityPass(for: activity, activeOnly: true) != nil { return true }
        if let any = activityPass(for: activity, activeOnly: false), any.voided {
            return false
        }
        return isJoined || isHost
    }

    func bookingPass(for recordID: UUID, activeOnly: Bool = true) -> PassRecord? {
        if activeOnly {
            return activePass(relatedID: recordID)
        }
        return activePass(relatedID: recordID) ?? pass(relatedID: recordID)
    }

    /// 票面展示用：作废态取任意记录；否则优先有效，回退任意。
    func resolvedBookingPass(for recordID: UUID, voided: Bool = false) -> PassRecord? {
        if voided {
            return bookingPass(for: recordID, activeOnly: false)
        }
        return bookingPass(for: recordID, activeOnly: true)
            ?? bookingPass(for: recordID, activeOnly: false)
    }

    /// 预览轨：排除已作废 / 退款 / 取消；完成票可保留。
    func shouldShowBookingOnPreviewRail(_ record: BuddyBookingRecord) -> Bool {
        switch record.status {
        case .refunded, .cancelled, .refunding:
            return false
        case .pendingConfirm, .awaitingPayment:
            return false
        case .paid, .inProgress, .completed:
            if let pass = bookingPass(for: record.id, activeOnly: false), pass.voided {
                return false
            }
            return true
        }
    }

    var activePasses: [PassRecord] {
        passes.filter { !$0.voided }
    }

    // MARK: - Issue (Source → Record)

    @discardableResult
    func issue(_ draft: PassDraft) -> PassRecord {
        if let related = draft.relatedID, let existing = pass(relatedID: related) {
            if existing.voided {
                return reinstate(existing, from: draft)
            }
            return existing
        }
        if let existing = pass(serialNumber: draft.serialNumber) {
            if existing.voided {
                return reinstate(existing, from: draft)
            }
            return existing
        }
        let record = PassRecord.from(draft: draft)
        passes.insert(record, at: 0)
        persist()
        return record
    }

    @discardableResult
    func issueActivityTicket(order: ActivityOrder, activity: Activity? = nil) -> PassRecord {
        issue(PassSourceFactory.activityTicket(order: order, activity: activity))
    }

    @discardableResult
    func issueActivityAttendanceTicket(for activity: Activity) -> PassRecord {
        if let existing = pass(relatedID: activity.id), !existing.voided {
            return existing
        }
        if let paid = ActivityPaymentStore.paidOrder(for: activity.id) {
            return issueActivityTicket(order: paid, activity: activity)
        }
        return issue(PassSourceFactory.activityAttendance(for: activity))
    }

    @discardableResult
    func issueBookingTicket(for record: BuddyBookingRecord) -> PassRecord {
        if let existing = pass(relatedID: record.id), !existing.voided {
            return refreshBookingFields(existing, from: record)
        }
        return issue(PassSourceFactory.bookingTicket(for: record))
    }

    @discardableResult
    func issueMembershipCard(holderName: String) -> PassRecord {
        issue(PassSourceFactory.membershipCard(holderName: holderName))
    }

    // MARK: - Update (same serial + token)

    @discardableResult
    func update(serialNumber: String, reason: String, mutate: (inout PassRecord) -> Void) -> PassRecord? {
        guard let index = passes.firstIndex(where: { $0.serialNumber == serialNumber }) else {
            return nil
        }
        mutate(&passes[index])
        passes[index].lastUpdated = .now
        if passes[index].distributionState == .draft {
            passes[index].distributionState = .ready
        }
        persist()
        PassUpdateWebService.shared.notePassUpdated(serialNumber: serialNumber, reason: reason)
        return passes[index]
    }

    /// 活动改期：按活动 relatedID 刷新时间字段。
    func refreshActivityPass(activity: Activity) {
        let draft = PassSourceFactory.activityAttendance(for: activity)
        if let paid = ActivityPaymentStore.paidOrder(for: activity.id) {
            let paidDraft = PassSourceFactory.activityTicket(order: paid, activity: activity)
            _ = update(serialNumber: paidDraft.serialNumber, reason: "活动信息更新") { record in
                applyDraftFields(paidDraft, to: &record)
            }
        }
        _ = update(serialNumber: draft.serialNumber, reason: "活动信息更新") { record in
            applyDraftFields(draft, to: &record)
        }
    }

    @discardableResult
    private func refreshBookingFields(_ existing: PassRecord, from record: BuddyBookingRecord) -> PassRecord {
        let draft = PassSourceFactory.bookingTicket(for: record)
        return update(serialNumber: existing.serialNumber, reason: "预约状态更新") { pass in
            applyDraftFields(draft, to: &pass)
        } ?? existing
    }

    private func reinstate(_ existing: PassRecord, from draft: PassDraft) -> PassRecord {
        update(serialNumber: existing.serialNumber, reason: "重新签发") { record in
            applyDraftFields(draft, to: &record)
            record.voided = false
            record.distributionState = .ready
        } ?? existing
    }

    private func applyDraftFields(_ draft: PassDraft, to record: inout PassRecord) {
        record.headerFields = draft.headerFields
        record.primaryFields = draft.primaryFields
        record.secondaryFields = draft.secondaryFields
        record.auxiliaryFields = draft.auxiliaryFields
        record.backFields = draft.backFields
        record.relevantDate = draft.relevantDate
        record.expirationDate = draft.expirationDate
        record.appearanceKey = draft.appearanceKey
        record.backgroundColorRGB = draft.backgroundColorRGB
    }

    // MARK: - Void / Revoke

    /// 官方语义：设 voided=true，同 serial 可再推送更新；保留记录。
    func void(relatedID: UUID) {
        guard let index = passes.firstIndex(where: { $0.relatedID == relatedID }) else { return }
        let serial = passes[index].serialNumber
        passes[index].voided = true
        passes[index].lastUpdated = .now
        persist()
        PassUpdateWebService.shared.noteVoid(serialNumber: serial)
    }

    /// 物理删除（演示重置 / 用户彻底清除）。
    func revoke(relatedID: UUID) {
        passes.removeAll { $0.relatedID == relatedID }
        persist()
    }

    func markExported(_ id: UUID) {
        guard let index = passes.firstIndex(where: { $0.id == id }) else { return }
        if passes[index].distributionState != .inSystemWallet {
            passes[index].distributionState = .exported
        }
        persist()
    }

    func markAddedToSystemWallet(_ id: UUID) {
        guard let index = passes.firstIndex(where: { $0.id == id }) else { return }
        passes[index].addedToSystemWallet = true
        passes[index].distributionState = .inSystemWallet
        persist()
    }

    func resetAll() {
        passes = []
        persist()
        PassUpdateWebService.shared.resetAll()
    }

    // MARK: - Persistence

    private static func load() -> [PassRecord] {
        let url = PassConfiguration.documentsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PassRecord].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist() {
        let url = PassConfiguration.documentsDirectory.appendingPathComponent(Self.fileName)
        guard let data = try? JSONEncoder().encode(passes) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}

typealias WalletPassStore = PassStore
