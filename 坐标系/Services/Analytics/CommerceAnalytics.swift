//
//  CommerceAnalytics.swift
//  坐标系
//
//  支付 / 钱包漏斗事件（禁止「演示成功」冒充转化，见 Project/18）。
//

import Foundation

enum CommerceAnalytics {
    static func checkoutBlocked(method: String) {
        Analytics.track("commerce_checkout_blocked", ["method": method])
    }

    static func topUpStart(channel: String, amountCents: Int, mode: String) {
        Analytics.track("commerce_topup_start", [
            "channel": channel,
            "amount_cents": "\(amountCents)",
            "mode": mode
        ])
    }

    static func topUpResult(channel: String, result: String) {
        Analytics.track("commerce_topup_result", [
            "channel": channel,
            "result": result
        ])
    }

    static func chargeResult(orderType: String, result: String, method: String) {
        Analytics.track("commerce_charge_result", [
            "order_type": orderType,
            "result": result,
            "method": method
        ])
    }

    static func refundSubmit(orderType: String, result: String) {
        Analytics.track("commerce_refund_submit", [
            "order_type": orderType,
            "result": result
        ])
    }

    static func withdrawBlocked() {
        Analytics.track("commerce_withdraw_blocked", ["reason": "not_open"])
    }

    static func invoiceBlocked() {
        Analytics.track("commerce_invoice_blocked", ["reason": "not_open"])
    }
}
