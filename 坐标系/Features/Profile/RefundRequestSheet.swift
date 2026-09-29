//
//  RefundRequestSheet.swift
//  坐标系
//
//  申请退款：策略说明 → 填原因与说明 → Alert 确认 → 提交至 RefundFlowService。
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

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
    static let scheduleLabel = "预约时间"
    static let durationLabel = "时长"
    static let paymentMethodLabel = "支付方式"
    static let slotLabel = "档期"
    static let evidenceLabel = "证明材料"
    static let policyDeniedFooter = "如有争议，可在「设置 → 帮助与反馈」联系客服。"
    static let evidenceAdd = "添加截图或照片"
    static func evidenceSelected(_ count: Int) -> String { "已选 \(count) 张，点击更换" }
    static let evidenceFooter = "可选；建议上传订单截图、聊天记录等，最多 4 张。"
    static let footer = "提交后将进入退款处理流程，按原支付方式退回。"

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
        "将退回 \(amountText)。确认后进入退款处理。"
    }
}

/// 退款申请表单：策略 → 填写 → Alert 确认 → 回调执行
struct RefundRequestSheet: View {
    let subjectTitle: String
    let amountText: String
    let reasons: [String]
    let policy: RefundPolicy.Evaluation
    var onConfirmed: (_ reason: String, _ detail: String, _ evidenceCount: Int) -> Bool
    private let extraOrderFields: [(title: String, value: String, systemImage: String)]

    @Environment(\.dismiss) private var dismiss
    @State private var reason: String
    @State private var detail = ""
    @State private var acknowledged = false
    @State private var showConfirmAlert = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewImages: [UIImage] = []

    private let maxEvidence = 4

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
            List {
                orderInfoSection
                policySection

                if policy.allowed {
                    reasonSection
                    detailSection
                    evidenceSection
                    acknowledgeSection
                }
            }
            .navigationTitle(RefundRequestCopy.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                if policy.allowed {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(RefundRequestCopy.submit) {
                            showConfirmAlert = true
                        }
                        .fontWeight(.semibold)
                        .disabled(!canSubmit)
                    }
                }
            }
            .alert(RefundRequestCopy.confirmTitle, isPresented: $showConfirmAlert) {
                Button(RefundRequestCopy.confirmCancel, role: .cancel) {}
                Button(RefundRequestCopy.confirmAction, role: .destructive) {
                    if onConfirmed(reason, composedDetail, previewImages.count) {
                        dismiss()
                    }
                }
            } message: {
                Text(RefundRequestCopy.confirmMessage(amountText: amountText))
            }
        }
        .platformSheet(.form)
    }

    @ViewBuilder
    private var orderInfoSection: some View {
        Section(RefundRequestCopy.orderSection) {
            LabeledContent(RefundRequestCopy.subjectLabel, value: subjectTitle)
            ForEach(Array(extraOrderFields.enumerated()), id: \.offset) { _, field in
                LabeledContent(field.title, value: field.value)
            }
            LabeledContent(RefundRequestCopy.amountLabel) {
                Text(amountText)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @ViewBuilder
    private var policySection: some View {
        Section {
            Label {
                Text(policy.headline)
            } icon: {
                Image(systemName: policy.allowed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
            }
            Text(policy.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } header: {
            Text(RefundRequestCopy.policySection)
        } footer: {
            if !policy.allowed {
                Text(RefundRequestCopy.policyDeniedFooter)
            }
        }
    }

    @ViewBuilder
    private var reasonSection: some View {
        Section {
            Picker(RefundRequestCopy.reasonHeader, selection: $reason) {
                ForEach(reasons, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text(RefundRequestCopy.reasonHeader)
        }
    }

    @ViewBuilder
    private var detailSection: some View {
        Section {
            TextField(
                RefundRequestCopy.detailPlaceholder,
                text: $detail,
                axis: .vertical
            )
            .lineLimit(4...8)
        } header: {
            Text(RefundRequestCopy.detailHeader)
        } footer: {
            Text("至少填写 4 个字，说明无法继续履约的原因。")
        }
    }

    @ViewBuilder
    private var evidenceSection: some View {
        Section {
            let evidencePickerTitle = PlatformPhotosPickerCopy.evidenceLabel(
                count: previewImages.count,
                emptyTitle: RefundRequestCopy.evidenceAdd,
                selectedTitle: RefundRequestCopy.evidenceSelected
            )
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: maxEvidence,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(evidencePickerTitle, systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: pickerItems) { _, items in
                Task { await loadEvidence(items) }
            }

            if !previewImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PlatformMetrics.hairlineSpacing) {
                        ForEach(Array(previewImages.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: PlatformMetrics.detailRelatedThumb,
                                    height: PlatformMetrics.detailRelatedThumb
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: PlatformMetrics.radiusMedia,
                                        style: .continuous
                                    )
                                )
                                .accessibilityLabel("证明材料 \(index + 1)")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        } header: {
            Text(RefundRequestCopy.evidenceLabel)
        } footer: {
            Text(RefundRequestCopy.evidenceFooter)
        }
    }

    @ViewBuilder
    private var acknowledgeSection: some View {
        Section {
            Toggle(RefundRequestCopy.acknowledgeLabel, isOn: $acknowledged)
        } footer: {
            Text(RefundRequestCopy.footer)
        }
    }

    private var composedDetail: String {
        guard !previewImages.isEmpty else { return trimmedDetail }
        return "\(trimmedDetail)\n附件 \(previewImages.count) 张"
    }

    @MainActor
    private func loadEvidence(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items.prefix(maxEvidence) {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else { continue }
            images.append(image)
        }
        previewImages = images
    }
}

extension RefundRequestSheet {
    init(
        subjectTitle: String,
        amountText: String,
        reasons: [String],
        policy: RefundPolicy.Evaluation,
        extraOrderFields: [(title: String, value: String, systemImage: String)] = [],
        onConfirmed: @escaping (_ reason: String, _ detail: String, _ evidenceCount: Int) -> Bool
    ) {
        self.subjectTitle = subjectTitle
        self.amountText = amountText
        self.reasons = reasons
        self.policy = policy
        self.extraOrderFields = extraOrderFields
        self.onConfirmed = onConfirmed
        _reason = State(initialValue: reasons.first ?? "")
    }

    static func activityOrder(
        _ order: ActivityOrder,
        activity: Activity?,
        refundNotes: [String] = [],
        onConfirmed: @escaping (_ reason: String, _ detail: String, _ evidenceCount: Int) -> Bool
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
        let method = PaymentMethod.resolve(order.paymentMethod)
        return RefundRequestSheet(
            subjectTitle: order.activityTitle,
            amountText: ActivityFeeParser.formattedPrice(cents: order.amountCents),
            reasons: RefundRequestCopy.activityReasons,
            policy: policy,
            extraOrderFields: [
                (RefundRequestCopy.paymentMethodLabel, method.displayName, "creditcard")
            ],
            onConfirmed: onConfirmed
        )
    }

    static func booking(
        _ record: BuddyBookingRecord,
        onConfirmed: @escaping (_ reason: String, _ detail: String, _ evidenceCount: Int) -> Bool
    ) -> RefundRequestSheet {
        let schedule = WalletPassFaceFactory.scheduleFields(from: record.scheduledAt)
        let method = PaymentMethod.resolve(record.paymentMethod)
        var extraOrderFields: [(title: String, value: String, systemImage: String)] = [
            (
                RefundRequestCopy.scheduleLabel,
                "\(schedule.label) \(schedule.value)",
                "calendar"
            ),
            (
                RefundRequestCopy.durationLabel,
                "\(record.hours) \(BuddyBookingFlowCopy.hoursUnit)",
                "clock"
            ),
            (RefundRequestCopy.paymentMethodLabel, method.displayName, "creditcard")
        ]
        if let slot = record.selectedSlotLabel, !slot.isEmpty {
            extraOrderFields.insert(
                (RefundRequestCopy.slotLabel, slot, "calendar.badge.clock"),
                at: 1
            )
        }

        let basePolicy = RefundPolicy.evaluateBooking(record: record)
        let policy = RefundPolicy.Evaluation(
            allowed: basePolicy.allowed,
            headline: basePolicy.headline,
            detail: "\(basePolicy.detail)\n\n\(BuddyBookingFlowCopy.bookingRefundPolicyNote)"
        )

        return RefundRequestSheet(
            subjectTitle: record.companionNickname,
            amountText: record.priceText,
            reasons: RefundRequestCopy.bookingReasons,
            policy: policy,
            extraOrderFields: extraOrderFields,
            onConfirmed: onConfirmed
        )
    }
}
