//
//  MessagesModel+Calling.swift
//  坐标系
//
//  本地模拟通话：发起 / 接通 / 挂断摘要。
//

import Foundation
import Observation
import CoordinateModels

extension MessagesModel {
    // MARK: - Calling

    @discardableResult
    func startVoiceCall(in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        startCall(kind: .voice, in: conversationID)
    }


    @discardableResult
    func startCall(kind: CallSessionKind, in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        guard index(of: conversationID) != nil else { return nil }
        if let active = activeCall(for: conversationID) { return active }
        let call = callingService.startCall(kind: kind, conversationID: conversationID)
        callRecords.insert(call, at: 0)
        appendSystemTip("已发起\(kind.rawValue)", audience: .everyone, to: conversationID)
        persist()
        return call
    }

    func connectCall(_ callID: CallSessionRecord.ID) {
        guard let index = callRecords.firstIndex(where: { $0.id == callID }),
              callRecords[index].status == .ringing || callRecords[index].status == .connecting
        else { return }
        callRecords[index].status = .active
        callRecords[index].connectedAt = .now
        persist()
    }

    func endCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .ended)
    }

    func rejectCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .rejected)
    }

    func cancelCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .cancelled)
    }

    func missCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .missed)
    }

    func updateCall(_ callID: CallSessionRecord.ID, to status: CallSessionStatus) {
        guard let index = callRecords.firstIndex(where: { $0.id == callID }) else { return }
        guard callRecords[index].status != status else { return }
        callRecords[index].status = status
        if callRecords[index].connectedAt == nil, status == .active {
            callRecords[index].connectedAt = .now
        }
        if status == .ended || status == .missed || status == .cancelled || status == .rejected {
            callRecords[index].endedAt = .now
            appendSystemTip(callSummary(callRecords[index]), audience: .everyone, to: callRecords[index].conversationID)
        }
        persist()
    }

    func callSummary(_ record: CallSessionRecord) -> String {
        switch record.status {
        case .missed:
            return "\(record.kind.rawValue)未接听"
        case .cancelled:
            return "\(record.kind.rawValue)已取消"
        case .rejected:
            return "\(record.kind.rawValue)已拒绝"
        case .ended:
            if let connectedAt = record.connectedAt, let endedAt = record.endedAt {
                let duration = max(Int(endedAt.timeIntervalSince(connectedAt)), 0)
                let minute = duration / 60
                let second = duration % 60
                return "\(record.kind.rawValue) \(String(format: "%02d:%02d", minute, second))"
            }
            return "\(record.kind.rawValue)已结束"
        case .ringing, .connecting, .active:
            return record.kind.rawValue
        }
    }
}
