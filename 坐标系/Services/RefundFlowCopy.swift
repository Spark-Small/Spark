//
//  RefundFlowCopy.swift
//  坐标系
//
//  退款流程文案。
//

import Foundation

enum RefundFlowCopy {
    static let statusNavigationTitle = "退款进度"
    static let submittedHint = "申请已提交，到账结果以支付服务商与运营审核为准"
    static let processingHint = "退款处理中，请稍候"
    static let rejectedHint = "退款未通过"
    static let viewWallet = "查看钱包"
    static let done = "完成"
    static let timelineTitle = "处理进度"
    static let reasonSection = "申请信息"
    static let orderSection = "订单信息"
    static let expeditedNote = "系统正在优先处理"

    static func completedMessage(amountDisplay: String, method: PaymentMethod) -> String {
        if method.affectsWalletBalance {
            return "\(amountDisplay) 已退回钱包余额"
        }
        return "\(amountDisplay) 将原路退回 \(method.displayName)"
    }
}

