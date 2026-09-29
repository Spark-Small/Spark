//
//  PassFacePresentation.swift
//  坐标系
//
//  PassKit eventTicket 字段模型：与 pass.json 同构，供行程凭证与 Wallet 导出共用。
//

import SwiftUI
import UIKit
import CoordinateModels

/// App 内 eventTicket 正面：对齐 pass.json header / primary / secondary / auxiliary。
struct PassFaceModel: Hashable {
    var logoText: String
    var headerFields: [PassField]
    var primaryFields: [PassField]
    var secondaryFields: [PassField]
    var auxiliaryFields: [PassField]
    var barcodeMessage: String
    /// pass.json `backgroundColor` — 字段 / 顶栏 / 条码区。
    var backgroundColor: Color
    /// Strip 插画区画布（独立于 backgroundColor）。
    var stripSurfaceColor: Color
    var voided: Bool = false
    /// Logo 下参与者（App 顶栏扩展；不在 auxiliary 重复）。
    var participantNickname: String?
    /// 条码下方订单编号。
    var orderNumber: String?
    /// 活动标题区右上角票种角标。
    var passKindTitle: String?

    static func from(_ draft: PassDraft) -> PassFaceModel {
        from(
            style: draft.style,
            headerFields: draft.headerFields,
            primaryFields: draft.primaryFields,
            secondaryFields: draft.secondaryFields,
            auxiliaryFields: draft.auxiliaryFields,
            barcodeMessage: draft.barcodeMessage,
            appearanceKey: draft.appearanceKey,
            backgroundColorRGB: draft.backgroundColorRGB,
            voided: false
        )
    }

    static func from(_ record: PassRecord) -> PassFaceModel {
        from(
            style: record.style,
            headerFields: record.headerFields,
            primaryFields: record.primaryFields,
            secondaryFields: record.secondaryFields,
            auxiliaryFields: record.auxiliaryFields,
            barcodeMessage: record.barcodeMessage,
            appearanceKey: record.appearanceKey,
            backgroundColorRGB: record.backgroundColorRGB,
            voided: record.voided
        )
    }

    private static func from(
        style: PassStyle,
        headerFields: [PassField],
        primaryFields: [PassField],
        secondaryFields: [PassField],
        auxiliaryFields: [PassField],
        barcodeMessage: String,
        appearanceKey: String?,
        backgroundColorRGB: String?,
        voided: Bool
    ) -> PassFaceModel {
        let palette = colors(
            style: style,
            appearanceKey: appearanceKey,
            backgroundColorRGB: backgroundColorRGB
        )
        return PassFaceModel(
            logoText: PassConfiguration.logoText,
            headerFields: headerFields,
            primaryFields: primaryFields,
            secondaryFields: secondaryFields,
            auxiliaryFields: auxiliaryFields,
            barcodeMessage: barcodeMessage,
            backgroundColor: palette.background,
            stripSurfaceColor: palette.stripSurface,
            voided: voided
        )
    }

    private static func colors(
        style: PassStyle,
        appearanceKey: String?,
        backgroundColorRGB: String?
    ) -> (background: Color, stripSurface: Color) {
        if style == .eventTicket {
            if let appearanceKey,
               let category = ActivityCategory(rawValue: appearanceKey) {
                return (
                    WalletPassEventTicketAppearance.backgroundColor(for: category),
                    WalletPassEventTicketAppearance.stripSurfaceColor(for: category)
                )
            }
            if let backgroundColorRGB,
               let uiColor = PassFaceColorParser.uiColor(fromRGBString: backgroundColorRGB) {
                return (
                    Color(uiColor: uiColor),
                    WalletPassEventTicketAppearance.stripSurfaceColor(for: .forYou)
                )
            }
            return (
                WalletPassEventTicketAppearance.backgroundColor(for: .forYou),
                WalletPassEventTicketAppearance.stripSurfaceColor(for: .forYou)
            )
        }
        return (
            legacyBackgroundColor(style: style, backgroundColorRGB: backgroundColorRGB),
            WalletPassEventTicketAppearance.stripSurfaceColor(for: .forYou)
        )
    }

    private static func legacyBackgroundColor(
        style: PassStyle,
        backgroundColorRGB: String?
    ) -> Color {
        if let backgroundColorRGB,
           let uiColor = PassFaceColorParser.uiColor(fromRGBString: backgroundColorRGB) {
            return Color(uiColor: uiColor)
        }
        switch style {
        case .eventTicket:
            return WalletPassEventTicketAppearance.backgroundColor(for: .forYou)
        case .coupon:
            return Color(red: 0.22, green: 0.28, blue: 0.18)
        case .storeCard:
            return Color(red: 0.28, green: 0.14, blue: 0.42)
        }
    }

    var accessibilitySummary: String {
        var parts: [String] = []
        if let kind = passKindTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !kind.isEmpty {
            parts.append(kind)
        }
        if let nickname = participantNickname?.trimmingCharacters(in: .whitespacesAndNewlines),
           !nickname.isEmpty {
            parts.append("参与者 \(nickname)")
        }
        appendFields(headerFields + primaryFields + secondaryFields + auxiliaryFields, to: &parts)
        if let orderNumber = orderNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
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

/// Pass 字段值排版：含数字的键用等宽数字，避免列对齐抖动。
enum PassFaceFieldFormatting {
    static func usesMonospacedDigits(key: String) -> Bool {
        switch key {
        case "seat", "attendance", "partySize", "reservation", "starts", "fee":
            return true
        default:
            return false
        }
    }
}

/// 行程页签发草稿：参与者 / 座位 / 票号写入 backFields，正面与 PassKit eventTicket 一致。
struct ActivityPassJourneyContext: Hashable {
    let userID: UUID
    let participantName: String
    let participantUIDDisplay: String
}

@MainActor
enum PassFacePresentation {
    static func activityJourneyFaceModel(
        for activity: Activity,
        voided: Bool,
        userID: UUID,
        participantName: String,
        participantUIDDisplay: String,
        barcodeMessage: String
    ) -> PassFaceModel {
        let draft = PassSourceFactory.activityJourneyDraft(
            for: activity,
            journey: ActivityPassJourneyContext(
                userID: userID,
                participantName: participantName,
                participantUIDDisplay: participantUIDDisplay
            )
        )
        var model = PassFaceModel.from(draft)
        model.voided = voided
        model.participantNickname = ActivityJourneyPresentation.participantNickname(
            name: participantName
        )
        model.orderNumber = ActivityTicketNumber.display(for: activity)
        model.passKindTitle = ActivityPassFieldBuilder.kind(for: activity.category).title
        if !barcodeMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            model.barcodeMessage = barcodeMessage
        }
        return model
    }
}

enum PassFaceColorParser {
    static func uiColor(fromRGBString rgb: String) -> UIColor? {
        let trimmed = rgb
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard trimmed.hasPrefix("rgb("), trimmed.hasSuffix(")") else { return nil }
        let inner = trimmed.dropFirst(4).dropLast()
        let components = inner.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard components.count == 3,
              let red = Double(components[0]),
              let green = Double(components[1]),
              let blue = Double(components[2])
        else { return nil }
        return UIColor(
            red: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: 1
        )
    }
}
