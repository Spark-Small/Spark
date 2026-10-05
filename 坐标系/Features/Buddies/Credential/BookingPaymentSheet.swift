//
//  BookingPaymentSheet.swift
//  坐标系
//
//  陪玩预约确认支付（商务结账；非登录 Sheet）。
//

import CoordinateModels
import SwiftUI

struct BookingPaymentSheet: View {
    let record: BuddyBookingRecord
    var onConfirm: (PaymentMethod) async -> PaymentOutcome
    var onCancel: () -> Void

    private var amountCents: Int {
        WalletMoney.cents(fromDisplay: record.priceText)
            ?? max(record.hours, 1) * 6_800
    }

    var body: some View {
        CoordinatePaymentSheet(
            navigationTitle: "确认支付",
            summary: [
                ("陪玩", record.companionNickname),
                ("时长", "\(record.hours) 小时"),
                (
                    "时间",
                    "\(Formatters.monthDay.string(from: record.scheduledAt)) \(Formatters.shortTime.string(from: record.scheduledAt))"
                )
            ],
            amountCents: amountCents,
            footer: "支付成功后将记入钱包流水。",
            preferredMethod: .wallet,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}
