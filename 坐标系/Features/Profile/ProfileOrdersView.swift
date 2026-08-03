//
//  ProfileOrdersView.swift
//  坐标系
//
//  「我的订单」：活动 / 陪玩（履约确认走行为信用，不对人公开打星）。
//

import SwiftUI

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
}

struct ProfileOrdersView: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(ActivitiesModel.self) private var activities
    @State private var segment: ProfileOrdersSegment = .all
    @State private var revision = 0

    private var activityItems: [ProfileCommerceOrderItem] {
        ActivityPaymentStore.allOrders().map(ProfileCommerceOrderItem.activity)
    }

    private var bookingItems: [ProfileCommerceOrderItem] {
        buddies.bookingRecords
            .filter {
                switch $0.status {
                case .pendingConfirm, .awaitingPayment, .paid, .inProgress, .completed, .refunded:
                    return true
                case .cancelled:
                    return false
                }
            }
            .map(ProfileCommerceOrderItem.booking)
    }

    private var orderItems: [ProfileCommerceOrderItem] {
        _ = revision
        let merged: [ProfileCommerceOrderItem]
        switch segment {
        case .all: merged = activityItems + bookingItems
        case .activity: merged = activityItems
        case .booking: merged = bookingItems
        }
        return merged.sorted { $0.sortDate > $1.sortDate }
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
        .listStyle(.insetGrouped)
        .navigationTitle("我的订单")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .onAppear { revision += 1 }
    }

    private var emptyTitle: String {
        switch segment {
        case .all: "还没有订单"
        case .activity: "还没有活动订单"
        case .booking: "还没有陪玩订单"
        }
    }

    private var emptyDescription: String {
        switch segment {
        case .all: "付费参加活动或支付陪玩预约后，记录会出现在这里。"
        case .activity: "付费参加活动后，支付单会出现在这里。"
        case .booking: "预约并支付陪玩后，订单会出现在这里。"
        }
    }

    @ViewBuilder
    private func orderRow(_ item: ProfileCommerceOrderItem) -> some View {
        switch item {
        case .activity(let order):
            NavigationLink {
                if let activity = activities.activity(id: order.activityID) {
                    ActivityDetailView(activity: activity)
                } else {
                    ContentUnavailableView("活动不可用", systemImage: "calendar")
                }
            } label: {
                orderLabel(
                    title: order.activityTitle,
                    subtitle: "活动 · \(ActivityPaymentStore.statusLabel(for: order.status))",
                    amount: ActivityFeeParser.formattedPrice(cents: order.amountCents),
                    time: Formatters.conversationListTime(from: order.createdAt),
                    systemImage: "calendar"
                )
            }
        case .booking(let record):
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

    private func orderLabel(
        title: String,
        subtitle: String,
        amount: String,
        time: String,
        systemImage: String
    ) -> some View {
        Label {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
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
