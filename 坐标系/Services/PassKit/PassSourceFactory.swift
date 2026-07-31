//
//  PassSourceFactory.swift
//  坐标系
//
//  Source：业务实体 → PassDraft（Creating the Source for a Pass）。
//

import Foundation

enum PassSourceFactory {
    static func activityTicket(order: ActivityOrder, activity: Activity? = nil) -> PassDraft {
        let place: String = {
            if let activity {
                return activity.districtLabel.isEmpty ? activity.location : activity.districtLabel
            }
            return ""
        }()
        let when = activity.map { Formatters.activityEventTime(from: $0.date) } ?? ""
        let fee = WalletMoney.formatted(cents: order.amountCents)
        let relevant = activity?.date
        return PassDraft(
            style: .eventTicket,
            serialNumber: order.id.uuidString,
            description: "活动报名凭证",
            primaryFields: [
                PassField(key: "event", label: "活动", value: order.activityTitle)
            ],
            secondaryFields: [
                PassField(key: "fee", label: "费用", value: fee)
            ],
            auxiliaryFields: [
                PassField(key: "when", label: "时间", value: when.isEmpty ? "见活动详情" : when),
                PassField(key: "where", label: "地点", value: place.isEmpty ? "见活动详情" : place)
            ],
            backFields: [
                PassField(key: "order", label: "订单号", value: order.id.uuidString),
                PassField(key: "method", label: "支付方式", value: order.paymentMethod),
                PassField(key: "locationFull", label: "详细地址", value: activity?.location ?? ""),
                PassField(key: "hint", label: "说明", value: "本地演示通行证。配置 Pass Type ID 并签名后可加入系统 Wallet。")
            ],
            barcodeMessage: "coordinate:activity:\(order.id.uuidString)",
            relevantDate: relevant,
            expirationDate: relevant.map { $0.addingTimeInterval(36 * 3600) },
            relatedID: order.id
        )
    }

    static func activityAttendance(for activity: Activity) -> PassDraft {
        let place = activity.districtLabel.isEmpty ? activity.location : activity.districtLabel
        return PassDraft(
            style: .eventTicket,
            serialNumber: activity.id.uuidString,
            description: "活动参加凭证",
            primaryFields: [
                PassField(key: "event", label: "活动", value: activity.title)
            ],
            secondaryFields: activity.fee.isEmpty ? [] : [
                PassField(key: "fee", label: "费用", value: activity.fee)
            ],
            auxiliaryFields: [
                PassField(key: "when", label: "时间", value: Formatters.activityEventTime(from: activity.date)),
                PassField(key: "where", label: "地点", value: place)
            ],
            backFields: [
                PassField(key: "locationFull", label: "详细地址", value: activity.location),
                PassField(key: "hint", label: "说明", value: "本地演示参加凭证，可在「我的活动」查看。")
            ],
            barcodeMessage: "coordinate:activity:\(activity.id.uuidString)",
            relevantDate: activity.date,
            expirationDate: activity.date.addingTimeInterval(36 * 3600),
            relatedID: activity.id
        )
    }

    static func bookingTicket(for record: BuddyBookingRecord) -> PassDraft {
        let when =
            "\(Formatters.monthDay.string(from: record.scheduledAt)) \(Formatters.shortTime.string(from: record.scheduledAt))"
        let duration = TimeInterval(max(record.hours, 1) * 3600)
        return PassDraft(
            style: .eventTicket,
            serialNumber: record.id.uuidString,
            description: "陪玩预约凭证",
            primaryFields: [
                PassField(key: "companion", label: "陪玩", value: record.companionNickname)
            ],
            secondaryFields: [
                PassField(key: "price", label: "费用", value: record.priceText)
            ],
            auxiliaryFields: [
                PassField(key: "when", label: "时间", value: when),
                PassField(key: "hours", label: "时长", value: "\(record.hours) 小时")
            ],
            backFields: [
                PassField(key: "status", label: "状态", value: record.statusLabel),
                PassField(key: "method", label: "支付", value: record.paymentMethod),
                PassField(key: "hint", label: "说明", value: "本地演示预约凭证，可在「我的陪玩」查看。")
            ],
            barcodeMessage: "coordinate:booking:\(record.id.uuidString)",
            relevantDate: record.scheduledAt,
            expirationDate: record.scheduledAt.addingTimeInterval(duration + 2 * 3600),
            relatedID: record.id
        )
    }

    static func membershipCard(holderName: String) -> PassDraft {
        let serial = "membership-\(LocalUserIdentity.current.uuidString)"
        return PassDraft(
            style: .storeCard,
            serialNumber: serial,
            description: "坐标系会员卡",
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
                PassField(key: "hint", label: "说明", value: "本地演示会员卡。签名后可加入 Apple Wallet。")
            ],
            barcodeMessage: "coordinate:membership:\(LocalUserIdentity.current.uuidString)",
            relevantDate: nil,
            expirationDate: nil,
            relatedID: nil
        )
    }
}
