//
//  ActivityOrdersViews.swift
//  坐标系
//
//  单场活动订单 Sheet / 行：支付续付与退款（无独立「我的订单」页）。
//

import SwiftUI
import CoordinateModels

@MainActor
struct ActivityOrdersSheet: View {
    let activityID: Activity.ID?
    /// 待支付续付：关闭本 Sheet 后由详情打开参加确认结账。
    var onResumePayment: (() -> Void)? = nil
    var onRefundCompleted: (() -> Void)? = nil

    @Environment(RefundFlowService.self) private var refunds
    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var orders: [ActivityOrder] = []
    @State private var refundError: String?
    @State private var refundTarget: ActivityOrder?
    @State private var presentedRefundRequestID: UUID?

    var body: some View {
        NavigationStack {
            ordersList
                .navigationTitle(ActivityDetailCopy.ordersTitle)
                .navigationBarTitleDisplayMode(.inline)
                .platformSheetConfirmationToolbar()
                .alert(
                    "无法退款",
                    isPresented: refundErrorPresented,
                    actions: { Button("好的", role: .cancel) {} },
                    message: { Text(refundError ?? "") }
                )
                .sheet(item: $refundTarget) { order in
                    refundRequestSheet(order)
                }
                .sheet(isPresented: refundStatusPresented) {
                    refundStatusSheet()
                }
                .onAppear(perform: reload)
        }
        .platformSheet(.browser)
    }

    @ViewBuilder
    private var ordersList: some View {
        Group {
            if orders.isEmpty {
                ContentUnavailableView {
                    Label(ActivityDetailCopy.ordersEmptyTitle, systemImage: "doc.text")
                } description: {
                    Text(ActivityDetailCopy.ordersEmptySubtitle)
                } actions: {
                    Button(ActivityDetailCopy.ordersEmptyAction) {
                        dismiss()
                        app.focusActivitiesDiscoverBrowse()
                    }
                }
                .platformContentUnavailablePageChrome()
            } else {
                List {
                    ForEach(orders) { order in
                        ActivityOrderRow(
                            order: order,
                            refundRequest: refunds.latestRequest(forOrderID: order.id),
                            onRefund: { refundTarget = order },
                            onResumePayment: resumePaymentAction(for: order)
                        )
                    }
                }
            }
        }
    }

    private var refundErrorPresented: Binding<Bool> {
        Binding(
            get: { refundError != nil },
            set: { if !$0 { refundError = nil } }
        )
    }

    private var refundStatusPresented: Binding<Bool> {
        Binding(
            get: { presentedRefundRequestID != nil },
            set: { if !$0 { presentedRefundRequestID = nil } }
        )
    }

    private func refundRequestSheet(_ order: ActivityOrder) -> some View {
        let activity = activities.activity(id: order.activityID)
        return RefundRequestSheet.activityOrder(
            order,
            activity: activity,
            refundNotes: refundNotes(for: activity)
        ) { reason, detail, _ in
            beginRefund(order, reason: reason, detail: detail)
        }
        .toolbarVisibility(.hidden, for: .tabBar)
    }

    @ViewBuilder
    private func refundStatusSheet() -> some View {
        if let requestID = presentedRefundRequestID {
            RefundStatusSheet(requestID: requestID)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    private func resumePaymentAction(for order: ActivityOrder) -> (() -> Void)? {
        guard order.status == .pending else { return nil }
        return { resumePayment() }
    }

    private func refundNotes(for activity: Activity?) -> [String] {
        guard let activity else { return [] }
        return ActivityDetailBlueprint.make(for: activity).refundNotes
    }

    private func resumePayment() {
        dismiss()
        onResumePayment?()
    }

    private func reload() {
        if let activityID {
            orders = ActivityPaymentStore.orders(for: activityID)
        } else {
            orders = ActivityPaymentStore.allOrders()
        }
    }

    @discardableResult
    private func beginRefund(_ order: ActivityOrder, reason: String, detail: String) -> Bool {
        let activity = activities.activity(id: order.activityID)
        let notes = refundNotes(for: activity)
        let result = refunds.submitActivityRefund(
            order: order,
            activity: activity,
            refundNotes: notes,
            reason: reason,
            detail: detail,
            cancelRegistration: false
        )
        switch result {
        case .success(let record):
            presentedRefundRequestID = record.id
            reload()
            onRefundCompleted?()
            return true
        case .failure(let error):
            refundError = error.localizedDescription
            return false
        }
    }
}

@MainActor
struct ActivityOrderRow: View {
    let order: ActivityOrder
    var refundRequest: RefundRequestRecord?
    var onRefund: () -> Void
    var onResumePayment: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading) {
            headerRow
            amountRow
            actionRow
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(order.activityTitle)
                    .font(.subheadline.weight(.semibold))
                Text(Formatters.conversationListTime(from: order.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(ActivityPaymentStore.statusLabel(for: order.status))
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, PlatformMetrics.chipPaddingHorizontalMini)
                .padding(.vertical, PlatformMetrics.chipPaddingVerticalMini)
                .background(PlatformSurface.tertiaryFill, in: Capsule())
        }
    }

    private var amountRow: some View {
        HStack {
            Text(ActivityFeeParser.formattedPrice(cents: order.amountCents))
                .font(.subheadline.weight(.semibold))
            Text("· \(order.paymentMethod)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        if order.status == .pending, let onResumePayment {
            Button(ActivityDetailCopy.resumePaymentAction, action: onResumePayment)
                .font(.subheadline.weight(.semibold))
        } else if order.status == .paid, refundRequest == nil {
            Button(ActivityDetailCopy.refundCTA, role: .destructive, action: onRefund)
                .font(.subheadline.weight(.semibold))
        } else if isRefundInFlight {
            Text(refundInFlightLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if order.status == .refunded {
            Text(ActivityDetailCopy.refundedHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var isRefundInFlight: Bool {
        order.status == .refunding
            || refundRequest?.status == .submitted
            || refundRequest?.status == .processing
    }

    private var refundInFlightLabel: String {
        if let refundRequest {
            return "\(ActivityDetailCopy.refundProcessing) · \(refundRequest.status.label)"
        }
        return ActivityDetailCopy.refundProcessing
    }

    private var statusColor: Color {
        switch order.status {
        case .paid: PlatformStatus.success
        case .pending, .refunding: PlatformStatus.warning
        case .refunded, .cancelled: .secondary
        }
    }
}
