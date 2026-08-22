//
//  RefundRequestSheet.swift
//  坐标系
//
//  申请退款：策略说明 → 填原因与说明 → Alert 确认 → 提交至 RefundFlowService。
//

import SwiftUI

enum RefundRequestCopy {
    static let navigationTitle = "申请退款"
    static let submit = "提交申请"
    static let confirmTitle = "确认申请退款？"
    static let confirmAction = "确认退款"
    static let confirmCancel = "再想想"
    static let reasonHeader = "退款原因"
    static let detailHeader = "补充说明"
    static let detailPlaceholder = "请说明具体情况，便于处理（必填）"
    static let acknowledgeLabel = "我已阅读退改说明，并确认申请退款"
    static let orderSection = "订单信息"
    static let policySection = "退改规则"
    static let amountLabel = "退款金额"
    static let subjectLabel = "对象"
    static let footer = "提交后将进入退款处理流程；演示环境按原支付方式退回，正式产品以实际到账规则为准。"

    static let activityReasons = [
        "行程冲突，无法参加",
        "个人原因无法参加",
        "活动信息与描述不符",
        "重复下单",
        "其他"
    ]

    static let bookingReasons = [
        "档期变更",
        "沟通不畅",
        "个人原因",
        "服务与描述不符",
        "其他"
    ]

    static func confirmMessage(amountText: String) -> String {
        "将退回 \(amountText)。确认后进入退款处理，演示环境按原支付方式到账。"
    }
}

/// 退款申请表单：策略 → 填写 → Alert 确认 → 回调执行
struct RefundRequestSheet: View {
    let subjectTitle: String
    let amountText: String
    let reasons: [String]
    let policy: RefundPolicy.Evaluation
    var onConfirmed: (_ reason: String, _ detail: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var detail = ""
    @State private var acknowledged = false
    @State private var showConfirmAlert = false

    private var trimmedDetail: String {
        detail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        policy.allowed
            && !reason.isEmpty
            && !trimmedDetail.isEmpty
            && trimmedDetail.count >= 4
            && acknowledged
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(RefundRequestCopy.subjectLabel) {
                        Text(subjectTitle)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent(RefundRequestCopy.amountLabel, value: amountText)
                } header: {
                    Text(RefundRequestCopy.orderSection)
                }

                Section {
                    Label(policy.headline, systemImage: policy.allowed ? "checkmark.seal" : "exclamationmark.triangle")
                        .foregroundStyle(policy.allowed ? PlatformStatus.success : PlatformStatus.warning)
                    Text(policy.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(RefundRequestCopy.policySection)
                }

                Section {
                    Picker(RefundRequestCopy.reasonHeader, selection: $reason) {
                        Text("请选择").tag("")
                        ForEach(reasons, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .disabled(!policy.allowed)
                } header: {
                    Text(RefundRequestCopy.reasonHeader)
                }

                Section {
                    TextField(
                        RefundRequestCopy.detailPlaceholder,
                        text: $detail,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .disabled(!policy.allowed)
                } header: {
                    Text(RefundRequestCopy.detailHeader)
                } footer: {
                    Text("至少填写 4 个字，说明无法继续履约的原因。")
                }

                Section {
                    Toggle(isOn: $acknowledged) {
                        Text(RefundRequestCopy.acknowledgeLabel)
                            .font(.subheadline)
                    }
                    .disabled(!policy.allowed)
                } footer: {
                    Text(RefundRequestCopy.footer)
                }
            }
            .navigationTitle(RefundRequestCopy.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(RefundRequestCopy.submit) {
                        showConfirmAlert = true
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSubmit)
                }
            }
            .alert(RefundRequestCopy.confirmTitle, isPresented: $showConfirmAlert) {
                Button(RefundRequestCopy.confirmCancel, role: .cancel) {}
                Button(RefundRequestCopy.confirmAction, role: .destructive) {
                    onConfirmed(reason, trimmedDetail)
                    dismiss()
                }
            } message: {
                Text(RefundRequestCopy.confirmMessage(amountText: amountText))
            }
        }
        .platformSheet(.form)
        .onAppear {
            if reason.isEmpty, let first = reasons.first {
                reason = first
            }
        }
    }
}

extension RefundRequestSheet {
    static func activityOrder(
        _ order: ActivityOrder,
        activity: Activity?,
        refundNotes: [String] = [],
        onConfirmed: @escaping (_ reason: String, _ detail: String) -> Void
    ) -> RefundRequestSheet {
        let policy: RefundPolicy.Evaluation = {
            guard let activity else {
                return RefundPolicy.Evaluation(
                    allowed: order.status == .paid,
                    headline: order.status == .paid ? "可申请退款" : "当前不可退",
                    detail: "提交后将进入退款处理流程。"
                )
            }
            return RefundPolicy.evaluateActivity(activity: activity, refundNotes: refundNotes)
        }()
        return RefundRequestSheet(
            subjectTitle: order.activityTitle,
            amountText: ActivityFeeParser.formattedPrice(cents: order.amountCents),
            reasons: RefundRequestCopy.activityReasons,
            policy: policy,
            onConfirmed: onConfirmed
        )
    }

    static func booking(
        _ record: BuddyBookingRecord,
        onConfirmed: @escaping (_ reason: String, _ detail: String) -> Void
    ) -> RefundRequestSheet {
        RefundRequestSheet(
            subjectTitle: record.companionNickname,
            amountText: record.priceText,
            reasons: RefundRequestCopy.bookingReasons,
            policy: RefundPolicy.evaluateBooking(record: record),
            onConfirmed: onConfirmed
        )
    }
}
