//
//  ProfileOrdersView.swift
//  坐标系
//
//  「我的订单」：活动 / 陪玩（履约确认走行为信用，不对人公开打星）。
//

import SwiftUI
import CoordinateModels

enum ProfileOrderShortcutFilter: String, CaseIterable, Identifiable, Hashable {
    case pendingPayment
    case pendingConfirm
    case pendingJoin
    case completed
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pendingPayment: "待支付"
        case .pendingConfirm: "待确认"
        case .pendingJoin: "待参与"
        case .completed: "已完成"
        case .cancelled: "已取消"
        }
    }

    var systemImage: String {
        switch self {
        case .pendingPayment: "creditcard.fill"
        case .pendingConfirm: "hourglass.circle.fill"
        case .pendingJoin: "ticket.fill"
        case .completed: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }
}

struct ProfileOrderShortcutCounts {
    var pendingPayment = 0
    var pendingConfirm = 0
    var pendingJoin = 0
    var completed = 0
    var cancelled = 0

    func count(for filter: ProfileOrderShortcutFilter) -> Int {
        switch filter {
        case .pendingPayment: pendingPayment
        case .pendingConfirm: pendingConfirm
        case .pendingJoin: pendingJoin
        case .completed: completed
        case .cancelled: cancelled
        }
    }

    static func compute(
        activityOrders: [ActivityOrder],
        bookingRecords: [BuddyBookingRecord]
    ) -> ProfileOrderShortcutCounts {
        var counts = ProfileOrderShortcutCounts()
        for order in activityOrders {
            switch order.status {
            case .pending: counts.pendingPayment += 1
            case .paid: counts.pendingJoin += 1
            case .cancelled: counts.cancelled += 1
            case .refunding, .refunded: counts.completed += 1
            }
        }
        for record in bookingRecords {
            switch record.status {
            case .awaitingPayment: counts.pendingPayment += 1
            case .pendingConfirm: counts.pendingConfirm += 1
            case .paid, .inProgress, .refunding: counts.pendingJoin += 1
            case .completed, .refunded: counts.completed += 1
            case .cancelled: counts.cancelled += 1
            }
        }
        return counts
    }
}

private enum ProfileOrdersSegment: String, CaseIterable, Identifiable {
    case all = "全部"
    case activity = "活动"
    case booking = "陪玩"

    var id: String { rawValue }
}

private enum ProfileCommerceOrderItem: Identifiable {
    case activity(ActivityOrder)
    case booking(BuddyBookingRecord)

    var id: String {
        switch self {
        case .activity(let order): "activity-\(order.id)"
        case .booking(let record): "booking-\(record.id)"
        }
    }

    var sortDate: Date {
        switch self {
        case .activity(let order): order.createdAt
        case .booking(let record): record.paidAt ?? record.bookedAt
        }
    }

    func matches(_ filter: ProfileOrderShortcutFilter) -> Bool {
        switch self {
        case .activity(let order):
            switch filter {
            case .pendingPayment: order.status == .pending
            case .pendingConfirm: false
            case .pendingJoin: order.status == .paid
            case .completed: order.status == .refunded || order.status == .refunding
            case .cancelled: order.status == .cancelled
            }
        case .booking(let record):
            switch filter {
            case .pendingPayment: record.status == .awaitingPayment
            case .pendingConfirm: record.status == .pendingConfirm
            case .pendingJoin: record.status == .paid || record.status == .inProgress || record.status == .refunding
            case .completed: record.status == .completed || record.status == .refunded
            case .cancelled: record.status == .cancelled
            }
        }
    }
}

struct ProfileOrdersView: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(ActivitiesModel.self) private var activities
    @Environment(RefundFlowService.self) private var refunds
    @Environment(\.activityZoomNamespace) private var zoomNamespace
    @State private var segment: ProfileOrdersSegment = .all
    @State private var shortcutFilter: ProfileOrderShortcutFilter?
    @State private var revision = 0

    init(initialShortcut: ProfileOrderShortcutFilter? = nil) {
        _shortcutFilter = State(initialValue: initialShortcut)
    }

    private var activityItems: [ProfileCommerceOrderItem] {
        ActivityPaymentStore.allOrders().map(ProfileCommerceOrderItem.activity)
    }

    private var bookingItems: [ProfileCommerceOrderItem] {
        buddies.bookingRecords.map(ProfileCommerceOrderItem.booking)
    }

    private var orderItems: [ProfileCommerceOrderItem] {
        _ = revision
        _ = refunds.requests.count
        let merged: [ProfileCommerceOrderItem]
        switch segment {
        case .all: merged = activityItems + bookingItems
        case .activity: merged = activityItems
        case .booking: merged = bookingItems
        }
        let sorted = merged.sorted { $0.sortDate > $1.sortDate }
        guard let shortcutFilter else { return sorted }
        return sorted.filter { $0.matches(shortcutFilter) }
    }

    var body: some View {
        List {
            Section {
                Picker("订单", selection: $segment) {
                    ForEach(ProfileOrdersSegment.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if let shortcutFilter {
                Section {
                    HStack {
                        Text("筛选：\(shortcutFilter.title)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button("清除") {
                            self.shortcutFilter = nil
                        }
                        .font(.subheadline)
                    }
                }
            }

            if orderItems.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "list.bullet.rectangle",
                    description: Text(emptyDescription)
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(orderItems) { item in
                        orderRow(item)
                    }
                } footer: {
                    Text("履约确认进入行为信用，不对人公开打星。")
                }
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle("我的订单")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { revision += 1 }
    }

    private var emptyTitle: String {
        if shortcutFilter != nil { return "没有符合条件的订单" }
        switch segment {
        case .all: return "还没有订单"
        case .activity: return "还没有活动订单"
        case .booking: return "还没有陪玩订单"
        }
    }

    private var emptyDescription: String {
        if shortcutFilter != nil {
            return "当前筛选下暂无记录，可清除筛选查看全部订单。"
        }
        switch segment {
        case .all: return "付费参加活动或支付陪玩预约后，记录会出现在这里。"
        case .activity: return "付费参加活动后，支付单会出现在这里。"
        case .booking: return "预约并支付陪玩后，订单会出现在这里。"
        }
    }

    @ViewBuilder
    private func orderRow(_ item: ProfileCommerceOrderItem) -> some View {
        switch item {
        case .activity(let order):
            if let refund = refunds.latestRequest(forOrderID: order.id),
               refund.status == .submitted || refund.status == .processing || order.status == .refunding {
                NavigationLink {
                    RefundStatusView(requestID: refund.id)
                } label: {
                    orderLabel(
                        title: order.activityTitle,
                        subtitle: "活动 · 退款\(refund.status.label)",
                        amount: ActivityFeeParser.formattedPrice(cents: order.amountCents),
                        time: Formatters.conversationListTime(from: order.createdAt),
                        systemImage: "arrow.uturn.backward.circle"
                    )
                }
            } else if order.status == .refunded,
                      let refund = refunds.latestRequest(forOrderID: order.id) {
                NavigationLink {
                    RefundStatusView(requestID: refund.id)
                } label: {
                    orderLabel(
                        title: order.activityTitle,
                        subtitle: "活动 · 已退款",
                        amount: ActivityFeeParser.formattedPrice(cents: order.amountCents),
                        time: Formatters.conversationListTime(from: refund.completedAt ?? order.createdAt),
                        systemImage: "calendar"
                    )
                }
            } else if let activity = activities.activity(id: order.activityID) {
                activityOrderLink(for: activity) {
                    orderLabel(
                        title: order.activityTitle,
                        subtitle: "活动 · \(ActivityPaymentStore.statusLabel(for: order.status))",
                        amount: ActivityFeeParser.formattedPrice(cents: order.amountCents),
                        time: Formatters.conversationListTime(from: order.createdAt),
                        systemImage: "calendar"
                    )
                }
            } else {
                NavigationLink {
                    ContentUnavailableView("活动不可用", systemImage: "calendar")
                } label: {
                    orderLabel(
                        title: order.activityTitle,
                        subtitle: "活动 · \(ActivityPaymentStore.statusLabel(for: order.status))",
                        amount: ActivityFeeParser.formattedPrice(cents: order.amountCents),
                        time: Formatters.conversationListTime(from: order.createdAt),
                        systemImage: "calendar"
                    )
                }
            }
        case .booking(let record):
            if record.status == .refunding,
               let refund = refunds.latestRequest(forOrderID: record.id) {
                NavigationLink {
                    RefundStatusView(requestID: refund.id)
                } label: {
                    orderLabel(
                        title: "陪玩 · \(record.companionNickname)",
                        subtitle: "退款中 · \(record.hours) 小时",
                        amount: record.priceText,
                        time: Formatters.conversationListTime(from: refund.createdAt),
                        systemImage: "arrow.uturn.backward.circle"
                    )
                }
            } else if let refund = refunds.latestRequest(forOrderID: record.id),
                      refund.status == .submitted || refund.status == .processing {
                NavigationLink {
                    RefundStatusView(requestID: refund.id)
                } label: {
                    orderLabel(
                        title: "陪玩 · \(record.companionNickname)",
                        subtitle: "退款\(refund.status.label) · \(record.hours) 小时",
                        amount: record.priceText,
                        time: Formatters.conversationListTime(from: record.paidAt ?? record.bookedAt),
                        systemImage: "arrow.uturn.backward.circle"
                    )
                }
            } else if record.status == .refunded,
                      let refund = refunds.latestRequest(forOrderID: record.id) {
                NavigationLink {
                    RefundStatusView(requestID: refund.id)
                } label: {
                    orderLabel(
                        title: "陪玩 · \(record.companionNickname)",
                        subtitle: "已退款 · \(record.hours) 小时",
                        amount: record.priceText,
                        time: Formatters.conversationListTime(from: refund.completedAt ?? record.paidAt ?? record.bookedAt),
                        systemImage: "arrow.uturn.backward.circle"
                    )
                }
            } else {
                NavigationLink {
                    BookingCredentialExpandedView(recordID: record.id)
                } label: {
                    orderLabel(
                        title: "陪玩 · \(record.companionNickname)",
                        subtitle: "\(record.statusLabel) · \(record.hours) 小时",
                        amount: record.priceText,
                        time: Formatters.conversationListTime(from: record.paidAt ?? record.bookedAt),
                        systemImage: "person.2.fill"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func activityOrderLink<Label: View>(
        for activity: Activity,
        @ViewBuilder label: @escaping () -> Label
    ) -> some View {
        if let zoomNamespace {
            ActivityZoomNavigationLink(activity: activity, namespace: zoomNamespace) {
                label()
            }
        } else {
            NavigationLink {
                ActivityDetailView(activity: activity)
                    .toolbarVisibility(.hidden, for: .tabBar)
            } label: {
                label()
            }
        }
    }

    private func orderLabel(
        title: String,
        subtitle: String,
        amount: String,
        time: String,
        systemImage: String
    ) -> some View {
        Label {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing * 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 8)
                Text(amount)
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .platformContentSymbolStyle()
    }
}
