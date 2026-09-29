//
//  LocalAuthSheet.swift
//  坐标系
//
//  Shared legal pages + booking payment sheet (launch UI lives under Features/Launch).
//

import SwiftUI
import CoordinateModels

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text(
                """
                隐私政策

                坐标系尊重你的隐私。当前版本将资料、活动与消息保存在本机，便于你离线使用与完整体验主流程。

                我们可能申请的权限：
                · 相册：发布封面、认证照与分享图片（上传前会做内容安全检测）
                · 日历：写入已报名活动
                · 定位：计算附近活动距离
                · 通知：活动、预约与消息提醒
                · 相机：形象认证时采集人脸，与你上传的认证照比对；影像优先本机处理
                · 跟踪：用于个性化推荐（需单独授权，可随时在系统设置关闭）

                形象认证与内容安全：
                · 认证照可用于核验本人身份；你可以关闭「对外展示」
                · 摄像头采集帧默认不用于公开展示；二次复核在青少年模式下不上云
                · 聊天、头像、社区与活动封面等上传图会经过不雅内容检测；误杀可申诉

                你的权利：
                · 在「设置 → 隐私」管理资料可见性
                · 在「设置 → 存储与导出」导出摘要或清理缓存
                · 通过「注销本地账号」删除本机身份、认证结果与业务数据

                未成年人保护：可在设置中开启青少年模式，限制充值与会员开通，并采用更严的内容阈值。正式版将补充监护人同意与内容分级。

                本政策适用于当前构建；上架正式版时将随云服务与第三方 SDK 同步更新，并提供独立隐私清单。
                """
            )
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UserAgreementView: View {
    var body: some View {
        ScrollView {
            Text(
                """
                用户协议

                欢迎使用坐标系。你可以通过本应用发现同城活动、匹配搭子、分享社区内容并与伙伴消息沟通。

                使用规范：
                · 遵守法律法规，不发布违法违规或不雅内容
                · 尊重他人，不骚扰、欺诈或冒用身份
                · 完成形象认证后方可使用报名、预约与消息等核心能力
                · 活动报名与陪玩预约以页面展示规则为准

                平台治理：
                · 提供内容安全检测、敏感词提示、举报、拉黑与社区公约
                · 形象认证误判或不雅图误杀可通过工单申诉
                · 严重违规可能导致功能限制；本机演示以工单状态机示意

                交易说明：
                · 陪玩预约与活动支付用于完成本地订单流程
                · 正式收款能力将另行接入合规支付渠道与发票能力

                账号：你可以随时退出登录或注销本地账号。注销不可恢复本机演示数据。

                继续使用即表示你已阅读并同意本协议及隐私政策。
                """
            )
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BookingPaymentSheet: View {
    let record: BuddyBookingRecord
    var onConfirm: (PaymentMethod) -> PaymentOutcome
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
