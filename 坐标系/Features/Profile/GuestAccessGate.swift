//
//  GuestAccessGate.swift
//  坐标系
//
//  访客门槛：交易 / 资料写入前要求创建账号。
//

import SwiftUI
import CoordinateModels

enum GuestAccessGate {
    static let commerceReason = "开通会员、充值与支付需先创建账号，便于保护余额与订单。"
    static let identityReason = "编辑个人资料需先创建账号，完整度与身份才会跨会话保留。"
    static let publishReason = "发布分享或发起活动需先创建账号。"
    static let youthCommerceReason = "青少年模式已开启，暂不可充值、开通会员或付费预约。"

    /// 访客则弹出创建账号，返回 false；已登录返回 true。
    @MainActor
    @discardableResult
    static func allow(
        _ auth: LocalAuthSession,
        presentCreateAccount: Binding<Bool>
    ) -> Bool {
        guard auth.isGuest else { return true }
        presentCreateAccount.wrappedValue = true
        return false
    }
}
