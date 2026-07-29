//
//  LocalAuthSheet.swift
//  坐标系
//
//  Shared legal pages + booking payment sheet (launch UI lives under Features/Launch).
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text(
                """
                隐私政策

                坐标系尊重你的隐私。当前版本将资料、活动与消息保存在本机，便于你离线使用与完整体验主流程。

                我们可能申请的权限：
                · 相册：发布封面与分享图片
                · 日历：写入已报名活动
                · 定位：计算附近活动距离
                · 通知：活动与预约提醒

                你可以在设置中管理通知与账号。如需清除本机数据，可在设置中登出并重置引导。
                """
            )
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

struct UserAgreementView: View {
    var body: some View {
        ScrollView {
            Text(
                """
                用户协议

                欢迎使用坐标系。你可以通过本应用发现同城活动、匹配搭子、分享社区内容并与伙伴消息沟通。

                你应遵守法律法规，不发布违法违规内容。平台提供敏感词提示、举报与拉黑等治理能力。

                陪玩预约中的支付确认用于完成本地订单流程；正式收款能力将另行接入合规支付渠道。
                """
            )
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

struct BookingPaymentSheet: View {
    let record: BuddyBookingRecord
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("订单确认") {
                    LabeledContent("陪玩", value: record.companionNickname)
                    LabeledContent("时长", value: "\(record.hours) 小时")
                    LabeledContent(
                        "时间",
                        value: "\(Formatters.monthDay.string(from: record.scheduledAt)) \(Formatters.shortTime.string(from: record.scheduledAt))"
                    )
                    LabeledContent("金额", value: record.priceText)
                }
                Section {
                    Text("支付方式：余额支付")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("确认支付")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("支付") {
                        onConfirm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .platformSheet(.confirm, interactiveDismissDisabled: true)
    }
}
