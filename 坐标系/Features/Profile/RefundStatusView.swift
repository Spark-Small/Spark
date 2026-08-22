//
//  RefundStatusView.swift
//  坐标系
//
//  退款进度详情：时间线 + 申请信息，对齐 Form / LabeledContent 官方样式。
//

import SwiftUI

struct RefundStatusView: View {
    let requestID: UUID

    @Environment(RefundFlowService.self) private var refunds
    @Environment(WalletStore.self) private var wallet
    @Environment(\.dismiss) private var dismiss

    private var record: RefundRequestRecord? {
        refunds.request(id: requestID)
    }

    var body: some View {
        Group {
            if let record {
                statusForm(record)
            } else {
                ContentUnavailableView(
                    "退款记录不可用",
                    systemImage: "arrow.uturn.backward.circle",
                    description: Text("该退款申请可能已被清除。")
                )
            }
        }
        .navigationTitle(RefundFlowCopy.statusNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func statusForm(_ record: RefundRequestRecord) -> some View {
        let method = PaymentMethod.resolve(record.paymentMethod)

        Form {
            Section {
                statusHeader(record, method: method)
            }

            Section(RefundFlowCopy.timelineTitle) {
                RefundTimelineRow(
                    title: "提交申请",
                    subtitle: record.initiator == .system ? "系统自动发起" : "用户提交",
                    timestamp: record.createdAt,
                    isComplete: true,
                    isCurrent: record.status == .submitted
                )
                RefundTimelineRow(
                    title: "处理中",
                    subtitle: record.status == .submitted
                        ? RefundFlowCopy.submittedHint
                        : RefundFlowCopy.processingHint,
                    timestamp: record.processingStartedAt,
                    isComplete: record.status != .submitted,
                    isCurrent: record.status == .processing
                )
                RefundTimelineRow(
                    title: record.status == .rejected ? "已拒绝" : "退款完成",
                    subtitle: completionSubtitle(record, method: method),
                    timestamp: record.completedAt,
                    isComplete: record.status == .completed || record.status == .rejected,
                    isCurrent: record.status == .completed || record.status == .rejected
                )
            }

            Section(RefundFlowCopy.orderSection) {
                LabeledContent("对象", value: record.subjectTitle)
                LabeledContent("退款金额", value: record.amountDisplay)
                LabeledContent("支付方式", value: method.displayName)
                LabeledContent("类型") {
                    Text(record.kind == .activity ? "活动订单" : "陪玩预约")
                }
            }

            Section(RefundFlowCopy.reasonSection) {
                LabeledContent("退款原因", value: record.reason)
                VStack(alignment: .leading, spacing: 6) {
                    Text("补充说明")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(record.detail)
                        .font(.body)
                }
            }

            if record.status == .completed, method.affectsWalletBalance {
                Section {
                    NavigationLink {
                        ProfileWalletView()
                    } label: {
                        Label(RefundFlowCopy.viewWallet, systemImage: "wallet.bifold")
                    }
                } footer: {
                    Text("当前余额 \(wallet.balanceText)")
                }
            }
        }
    }

    @ViewBuilder
    private func statusHeader(_ record: RefundRequestRecord, method: PaymentMethod) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
            HStack(spacing: 10) {
                Image(systemName: statusIcon(record.status))
                    .font(.title2)
                    .foregroundStyle(statusColor(record.status))
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.status.label)
                        .font(.headline)
                    Text(statusHint(record, method: method))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if record.initiator == .system {
                Text(RefundFlowCopy.expeditedNote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func statusIcon(_ status: RefundRequestStatus) -> String {
        switch status {
        case .submitted: "clock.arrow.circlepath"
        case .processing: "hourglass.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .rejected: "xmark.circle.fill"
        }
    }

    private func statusColor(_ status: RefundRequestStatus) -> Color {
        switch status {
        case .submitted, .processing: PlatformStatus.warning
        case .completed: PlatformStatus.success
        case .rejected: PlatformStatus.danger
        }
    }

    private func statusHint(_ record: RefundRequestRecord, method: PaymentMethod) -> String {
        switch record.status {
        case .submitted: RefundFlowCopy.submittedHint
        case .processing: RefundFlowCopy.processingHint
        case .completed: RefundFlowCopy.completedMessage(
            amountDisplay: record.amountDisplay,
            method: method
        )
        case .rejected: record.rejectionMessage ?? RefundFlowCopy.rejectedHint
        }
    }

    private func completionSubtitle(_ record: RefundRequestRecord, method: PaymentMethod) -> String {
        if record.status == .rejected {
            return record.rejectionMessage ?? RefundFlowCopy.rejectedHint
        }
        if record.status == .completed {
            return RefundFlowCopy.completedMessage(amountDisplay: record.amountDisplay, method: method)
        }
        return "等待处理"
    }
}

private struct RefundTimelineRow: View {
    let title: String
    let subtitle: String
    let timestamp: Date?
    let isComplete: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? PlatformStatus.success : Color.secondary.opacity(0.4))
                .font(.body)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let timestamp {
                    Text(Formatters.conversationListTime(from: timestamp))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

/// Sheet 包装：提交后展示进度
struct RefundStatusSheet: View {
    let requestID: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            RefundStatusView(requestID: requestID)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(RefundFlowCopy.done) { dismiss() }
                    }
                }
        }
        .platformSheet(.browser)
    }
}
