//
//  PassSourceFactory.swift
//  坐标系
//
//  Source：业务实体 → PassDraft（Apple eventTicket 模板字段布局）。
//

import Foundation
import CoordinateModels

@MainActor
enum PassSourceFactory {
    /// 行程页 live 草稿：与签发 pass.json 同构，含参与者 / 座位 / 票号（backFields）。
    static func activityJourneyDraft(
        for activity: Activity,
        journey: ActivityPassJourneyContext
    ) -> PassDraft {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            return activityTicket(order: order, activity: activity, journey: journey)
        }
        return activityAttendance(for: activity, journey: journey)
    }

    static func activityTicket(
        order: ActivityOrder,
        activity: Activity? = nil,
        journey: ActivityPassJourneyContext? = nil
    ) -> PassDraft {
        return activityPassDraft(
            title: order.activityTitle,
            serialNumber: order.id.uuidString,
            description: "活动报名凭证",
            feeLine: WalletMoney.formatted(cents: order.amountCents),
            activity: activity,
            relatedID: order.id,
            journey: journey,
            backExtra: [
                PassField(key: "order", label: "订单号", value: order.id.uuidString),
                PassField(key: "method", label: "支付方式", value: order.paymentMethod)
            ]
        )
    }

    static func activityAttendance(
        for activity: Activity,
        journey: ActivityPassJourneyContext? = nil
    ) -> PassDraft {
        activityPassDraft(
            title: activity.title,
            serialNumber: activity.id.uuidString,
            description: "活动参加凭证",
            feeLine: activity.isFree ? ActivityCardStatus.free : activity.fee,
            activity: activity,
            relatedID: activity.id,
            journey: journey,
            backExtra: []
        )
    }

    private static func activityPassDraft(
        title: String,
        serialNumber: String,
        description: String,
        feeLine: String,
        activity: Activity?,
        relatedID: UUID,
        journey: ActivityPassJourneyContext?,
        backExtra: [PassField]
    ) -> PassDraft {
        let location = activity.map { ActivityPassFieldBuilder.locationValue(for: $0) } ?? "见活动详情"
        let schedule = activity.map { WalletPassFaceFactory.scheduleFields(from: $0.date) }
        let appearance = activity.map { PassTemplateResources.activityAppearance(for: $0.category) }
        let relevant = activity?.date
        var backFields: [PassField] = [
            PassField(key: "locationFull", label: "详细地址", value: activity?.location ?? ""),
            PassField(key: "host", label: ActivityPassCopy.organizer, value: activity?.hostName ?? ""),
            PassField(key: "hint", label: "说明", value: "持此凭证入场；可在「我的 → 活动凭证」查看。")
        ]
        if let journey {
            backFields.append(contentsOf: journeyBackFields(
                activity: activity,
                relatedID: relatedID,
                journey: journey
            ))
        }
        backFields.append(contentsOf: backExtra)

        return PassDraft(
            style: .eventTicket,
            serialNumber: serialNumber,
            description: description,
            headerFields: schedule.map {
                [
                    PassField(key: "starts", label: $0.label, value: $0.value)
                ]
            } ?? [],
            primaryFields: [
                PassField(key: "event", label: ActivityPassCopy.activity, value: title)
            ],
            secondaryFields: [
                PassField(key: "where", label: ActivityPassCopy.location, value: location)
            ],
            auxiliaryFields: activity.map {
                ActivityPassFieldBuilder.auxiliaryFields(
                    for: $0,
                    feeLine: feeLine,
                    journey: journey
                )
            } ?? [PassField(key: "fee", label: ActivityPassCopy.fee, value: feeLine)],
            backFields: backFields,
            barcodeMessage: "coordinate:activity:\(relatedID.uuidString)",
            relevantDate: relevant,
            expirationDate: relevant.map { $0.addingTimeInterval(36 * 3600) },
            relatedID: relatedID,
            appearanceKey: activity?.category.rawValue,
            backgroundColorRGB: appearance?.backgroundRGB
        )
    }

    private static func journeyBackFields(
        activity: Activity?,
        relatedID: UUID,
        journey: ActivityPassJourneyContext
    ) -> [PassField] {
        let ticketValue: String = {
            if let activity {
                return ActivityTicketNumber.display(for: activity)
            }
            return ActivityTicketNumber.format(relatedID)
        }()
        let participant = ActivityJourneyPresentation.participantLine(
            name: journey.participantName,
            uidDisplay: journey.participantUIDDisplay
        )
        return [
            PassField(key: "ticket", label: "票号", value: ticketValue),
            PassField(key: "participant", label: "参与者", value: participant)
        ]
    }

    static func bookingTicket(for record: BuddyBookingRecord) -> PassDraft {
        let schedule = WalletPassFaceFactory.scheduleFields(from: record.scheduledAt)
        let duration = TimeInterval(max(record.hours, 1) * 3600)
        let appearanceRGB = PassTemplateResources.rgbString(red: 28, green: 14, blue: 42)
        return PassDraft(
            style: .eventTicket,
            serialNumber: record.id.uuidString,
            description: "陪玩预约凭证",
            headerFields: [
                PassField(key: "starts", label: schedule.label, value: schedule.value)
            ],
            primaryFields: [
                PassField(key: "companion", label: "陪玩", value: record.companionNickname)
            ],
            secondaryFields: [
                PassField(key: "plan", label: "预约", value: "\(record.hours) 小时 · \(record.priceText)")
            ],
            auxiliaryFields: [
                PassField(key: "status", label: "状态", value: record.statusLabel),
                PassField(key: "method", label: "支付", value: record.paymentMethod)
            ],
            backFields: [
                PassField(key: "hint", label: "说明", value: "本地演示预约凭证，可在「我的 → 陪玩预约」查看。")
            ],
            barcodeMessage: "coordinate:booking:\(record.id.uuidString)",
            relevantDate: record.scheduledAt,
            expirationDate: record.scheduledAt.addingTimeInterval(duration + 2 * 3600),
            relatedID: record.id,
            appearanceKey: PassStyle.eventTicket.rawValue,
            backgroundColorRGB: appearanceRGB
        )
    }

    static func membershipCard(holderName: String) -> PassDraft {
        let serial = "membership-\(LocalUserIdentity.current.uuidString)"
        return PassDraft(
            style: .storeCard,
            serialNumber: serial,
            description: "坐标系会员卡",
            headerFields: [],
            primaryFields: [
                PassField(key: "member", label: "会员", value: holderName)
            ],
            secondaryFields: [
                PassField(key: "tier", label: "等级", value: "演示会员")
            ],
            auxiliaryFields: [
                PassField(key: "perks", label: "权益", value: "优先提醒 · 专属标识")
            ],
            backFields: [
                PassField(key: "hint", label: "说明", value: "演示会员卡。签名后可加入 Apple Wallet。")
            ],
            barcodeMessage: "coordinate:membership:\(LocalUserIdentity.current.uuidString)",
            relevantDate: nil,
            expirationDate: nil,
            relatedID: nil,
            appearanceKey: PassStyle.storeCard.rawValue,
            backgroundColorRGB: PassTemplateResources.rgbString(red: 28, green: 14, blue: 42)
        )
    }
}
