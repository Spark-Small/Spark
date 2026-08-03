//
//  RefundRequestSheet.swift
//  坐标系
//
//  申请退款：先填原因与说明，再经 Alert 确认后执行。
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
    static let amountLabel = "退款金额"
    static let subjectLabel = "对象"
    static let footer = "提交后需再次确认。演示环境将按原支付方式退回；正式产品以实际到账规则为准。"

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
        "将退回 \(amountText)。确认后订单结束，演示环境按原支付方式处理。"
    }
}

/// 退款申请表单：填写 → Alert 确认 → 回调执行退款
struct RefundRequestSheet: View {
    let subjectTitle: String
    let amountText: String
    let reasons: [String]
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
        !reason.isEmpty
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
                    Picker(RefundRequestCopy.reasonHeader, selection: $reason) {
                        Text("请选择").tag("")
                        ForEach(reasons, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
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
        onConfirmed: @escaping (_ reason: String, _ detail: String) -> Void
    ) -> RefundRequestSheet {
        RefundRequestSheet(
            subjectTitle: order.activityTitle,
            amountText: ActivityFeeParser.formattedPrice(cents: order.amountCents),
            reasons: RefundRequestCopy.activityReasons,
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
            onConfirmed: onConfirmed
        )
    }
}
