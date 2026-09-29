//
//  WalletPassFaceFactory.swift
//  坐标系
//
//  域实体 → WalletPassFaceContent（活动 / 预约 / 会员 / PassRecord）。
//

import SwiftUI
import CoordinateModels

// MARK: - Domain adapters

enum WalletPassPublishedKind: Hashable {
    case post
    case hostedActivity

    var badge: String {
        switch self {
        case .post: "作品"
        case .hostedActivity: "发起"
        }
    }

    var systemImage: String {
        switch self {
        case .post: "text.below.photo"
        case .hostedActivity: "flag.fill"
        }
    }
}

enum WalletPassFaceFactory {
    /// 右上 headerFields：label = 星期+时刻，value = 月日
    static func scheduleFields(from date: Date) -> (label: String, value: String) {
        let label =
            "\(Formatters.weekday.string(from: date)) \(Formatters.shortTime.string(from: date))"
        let value = Formatters.monthDay.string(from: date)
        return (label, value)
    }

    /// 列表长条：一行日程（今天/明天/星期 · 时刻）
    static func listScheduleLine(from date: Date) -> String {
        Formatters.activityEventTime(from: date)
    }

    @MainActor
    static func activity(
        _ activity: Activity,
        barcodeMessage: String? = nil,
        voided: Bool = false
    ) -> WalletPassFaceContent {
        let blueprint = ActivityDetailBlueprint.make(for: activity)
        let schedule = scheduleFields(from: activity.date)
        return WalletPassFaceContent(
            logoText: activity.title,
            logoSystemImage: "ticket",
            subtitleText: attendanceHint(for: activity),
            headerLabel: schedule.label,
            headerValue: schedule.value,
            locationText: activity.location,
            showsNavigateButton: !activity.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            showsDetailButton: true,
            arrangementLines: arrangementLines(from: blueprint.timeline),
            detailNotes: detailNotes(from: blueprint),
            barcodeKind: .code128,
            barcodeMessage: barcodeMessage ?? "coordinate:activity:\(activity.id.uuidString)",
            stripColor: stripColor(for: activity.category),
            voided: voided
        )
    }

    /// 活动票底色：按分类区分，避免长条叠放一片近黑。
    static func stripColor(for category: ActivityCategory) -> Color {
        switch category {
        case .outdoorSports:
            return Color(red: 0.14, green: 0.36, blue: 0.52)
        case .food:
            return Color(red: 0.48, green: 0.28, blue: 0.16)
        case .interestSocial:
            return Color(red: 0.34, green: 0.28, blue: 0.54)
        case .cityExplore:
            return Color(red: 0.16, green: 0.40, blue: 0.42)
        case .handmade:
            return Color(red: 0.46, green: 0.30, blue: 0.38)
        case .learning:
            return Color(red: 0.22, green: 0.36, blue: 0.50)
        case .entertainment:
            return Color(red: 0.44, green: 0.20, blue: 0.34)
        case .all, .forYou:
            return Color(red: 0.18, green: 0.32, blue: 0.48)
        }
    }

    /// 票面「活动安排」：时间 + 节点标题
    static func arrangementLines(from timeline: [ActivityDetailTimelineItem], limit: Int = 4) -> [String] {
        timeline.prefix(limit).map { item in
            let time = item.time.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if time.isEmpty { return title }
            if title.isEmpty { return time }
            return "\(time) · \(title)"
        }
        .filter { !$0.isEmpty }
    }

    /// 票面「细则注意事项」：准备注意 + 参加须知，去空后截断
    static func detailNotes(from blueprint: ActivityDetailBlueprint, limit: Int = 4) -> [String] {
        var lines: [String] = []
        lines.append(contentsOf: blueprint.prepNotes)
        lines.append(contentsOf: blueprint.registrationNotes)
        return Array(
            lines
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(limit)
        )
    }

    /// 标题下人数提示：只显示已参加人数
    static func attendanceHint(for activity: Activity) -> String {
        "\(activity.joined) 人参加"
    }

    static func booking(
        _ record: BuddyBookingRecord,
        statusOverride: String? = nil,
        barcodeMessage: String? = nil,
        voided: Bool = false
    ) -> WalletPassFaceContent {
        let isVoided = voided || statusOverride == "已作废"
        let schedule = scheduleFields(from: record.scheduledAt)
        let status = statusOverride ?? record.statusLabel
        return WalletPassFaceContent(
            logoText: record.companionNickname,
            logoSystemImage: "person.2.fill",
            subtitleText: status,
            headerLabel: schedule.label,
            headerValue: schedule.value,
            locationLabel: "预约",
            locationText: "\(record.hours) 小时 · \(record.priceText)",
            showsNavigateButton: false,
            showsMessageButton: true,
            showsDetailButton: true,
            barcodeKind: .code128,
            barcodeMessage: barcodeMessage ?? "coordinate:booking:\(record.id.uuidString)",
            stripColor: Color(red: 0.28, green: 0.14, blue: 0.42),
            voided: isVoided
        )
    }

    static func membership(holderName: String, tier: String = "演示会员") -> WalletPassFaceContent {
        WalletPassFaceContent(
            logoText: PassConfiguration.logoText,
            logoSystemImage: "person.text.rectangle",
            headerValue: tier,
            locationText: holderName,
            showsNavigateButton: false,
            barcodeKind: .code128,
            barcodeMessage: "coordinate:membership:\(LocalUserIdentity.current.uuidString)",
            stripColor: Color(red: 0.22, green: 0.28, blue: 0.18)
        )
    }

    static func published(
        kind: WalletPassPublishedKind,
        title: String,
        metaLine: String,
        idHint: String
    ) -> WalletPassFaceContent {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = trimmed.isEmpty ? kind.badge : trimmed
        return WalletPassFaceContent(
            logoText: displayTitle,
            logoSystemImage: kind.systemImage,
            headerValue: kind.badge,
            locationText: metaLine,
            showsNavigateButton: false,
            barcodeKind: .code128,
            barcodeMessage: "coordinate:published:\(kind.badge):\(idHint)",
            stripColor: Color(red: 0.15, green: 0.22, blue: 0.38)
        )
    }

    /// PassRecord → 票面；活动票优先用 when/where 填日程与地点。
    static func fromPassRecord(_ pass: PassRecord) -> WalletPassFaceContent {
        let color: Color = {
            switch pass.style {
            case .eventTicket: return Color(red: 0.18, green: 0.32, blue: 0.48)
            case .coupon: return Color(red: 0.22, green: 0.28, blue: 0.18)
            case .storeCard: return Color(red: 0.28, green: 0.14, blue: 0.42)
            }
        }()

        switch pass.style {
        case .storeCard:
            let tier = pass.secondaryFields.first?.value ?? ""
            let member = pass.primaryFields.first?.value ?? ""
            return WalletPassFaceContent(
                logoText: PassConfiguration.logoText,
                logoSystemImage: pass.style.systemImage,
                headerValue: tier,
                locationText: member,
                showsNavigateButton: false,
                barcodeKind: .code128,
                barcodeMessage: pass.barcodeMessage,
                stripColor: color,
                voided: pass.voided
            )

        case .eventTicket, .coupon:
            let title = pass.primaryFields.first?.value ?? pass.description
            let header = pass.headerFields.first
            let place = pass.field(key: "where")?.value
                ?? pass.field(key: "hours")?.value
                ?? ""
            let hours = pass.field(key: "hours")?.value
            let fee = pass.field(key: "fee")?.value ?? pass.field(key: "price")?.value
            let location: String = {
                if let hours, let fee { return "\(hours) · \(fee)" }
                if !place.isEmpty { return place }
                return fee ?? ""
            }()
            let stripColor: Color = {
                if let key = pass.appearanceKey,
                   let category = ActivityCategory(rawValue: key) {
                    return WalletPassFaceFactory.stripColor(for: category)
                }
                return color
            }()
            return WalletPassFaceContent(
                logoText: title,
                logoSystemImage: pass.style.systemImage,
                headerLabel: header?.label ?? "",
                headerValue: header?.value ?? "",
                locationText: location,
                showsNavigateButton: pass.field(key: "where") != nil && !(pass.field(key: "where")?.value.isEmpty ?? true),
                barcodeKind: .code128,
                barcodeMessage: pass.barcodeMessage,
                stripColor: stripColor,
                voided: pass.voided
            )
        }
    }

    @MainActor
    static func stripPhoto(
        for pass: PassRecord,
        activities: ActivitiesModel,
        buddies: BuddiesModel
    ) -> CommunityPhotoRef? {
        guard let related = pass.relatedID else { return nil }

        if let activity = activities.activity(id: related) {
            return activity.coverPhoto
        }
        if let order = ActivityPaymentStore.order(id: related),
           let activity = activities.activity(id: order.activityID) {
            return activity.coverPhoto
        }
        if let booking = buddies.bookingRecords.first(where: { $0.id == related }) {
            return buddies.item(for: booking.companionNickname)?.profile.coverPhoto
        }
        return nil
    }
}
