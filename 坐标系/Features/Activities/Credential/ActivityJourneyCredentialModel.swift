//
//  ActivityJourneyCredentialModel.swift
//  坐标系
//
//  App 内活动凭证：履约态 / 纪念态双形态（与 PassKit 导出解耦）。
//

import SwiftUI
import CoordinateModels

/// 凭证在 App 内的呈现态。
enum ActivityJourneyCredentialPresentationMode: Hashable {
    /// 履约：完整字段 + 条码 + 订单号。
    case fulfillment
    /// 纪念：活动结束后；隐藏履约码，强化晒图。
    case memento
    case voided
}

struct ActivityJourneyCredentialModel: Hashable {
    var face: PassFaceModel
    var presentation: ActivityJourneyCredentialPresentationMode
    var artScene: CredentialArtScene
    var artTheme: CredentialArtTheme
    /// 纪念态角标（如「感谢参与」「纪念行程」）。
    var mementoHeadline: String?

    var showsBarcode: Bool {
        guard presentation == .fulfillment, !face.voided else { return false }
        return !face.barcodeMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var showsOrderNumber: Bool {
        presentation == .fulfillment && !face.voided
    }

    var accessibilitySummary: String {
        var parts: [String] = []
        if let headline = mementoHeadline?.trimmingCharacters(in: .whitespacesAndNewlines),
           !headline.isEmpty,
           presentation == .memento {
            parts.append(headline)
        }
        if let kind = face.passKindTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !kind.isEmpty {
            parts.append(kind)
        }
        if let nickname = face.participantNickname?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !nickname.isEmpty {
            parts.append("参与者 \(nickname)")
        }
        appendFields(
            face.headerFields + face.primaryFields + face.secondaryFields + face.auxiliaryFields,
            to: &parts
        )
        if showsOrderNumber,
           let orderNumber = face.orderNumber?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !orderNumber.isEmpty {
            parts.append("订单编号 \(orderNumber)")
        }
        return parts.joined(separator: "，")
    }

    private func appendFields(_ fields: [PassField], to parts: inout [String]) {
        for field in fields {
            let label = field.label.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { continue }
            if label.isEmpty {
                parts.append(value)
            } else {
                parts.append("\(label) \(value)")
            }
        }
    }
}
