//
//  ProfileSocialViews.swift
//  坐标系
//
//  「我的」二级页：圈子、我的陪玩（陪玩预约 + 活动邀约）。
//

import SwiftUI

// MARK: - Circles

struct ProfileCirclesListView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            if buddies.joinedCircles.isEmpty {
                ContentUnavailableView(
                    "还没有加入圈子",
                    systemImage: "person.3",
                    description: Text("去搭子页看看，找到合适的兴趣组织加入。")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(buddies.joinedCircles) { circle in
                    NavigationLink(value: circle) {
                        ProfileCircleRow(circle: circle, isJoined: true)
                    }
                }
            }
        }
        .navigationTitle("我的圈子")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ProfileCircleDiscoverView()
                } label: {
                    Text("发现")
                }
            }
        }
        .circleDetailNavigationDestination()
    }
}

struct ProfileCircleDiscoverView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            if buddies.allCircles.isEmpty {
                ContentUnavailableView(
                    "暂时没有可加入的组织",
                    systemImage: "person.3",
                    description: Text("附近组织都已加入，可在「我的圈子」里查看。")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(buddies.allCircles) { circle in
                    NavigationLink(value: circle) {
                        ProfileCircleRow(circle: circle, isJoined: false)
                    }
                }
            }
        }
        .navigationTitle("发现圈子")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .circleDetailNavigationDestination()
    }
}

private struct ProfileCircleRow: View {
    let circle: InterestCircle
    var isJoined: Bool

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(circle.name)
                        .font(PlatformListTypography.primary)
                    if isJoined {
                        Text("已加入")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PlatformStatus.success)
                    }
                }
                Text("\(circle.city) · \(circle.topic)")
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
                Text("\(circle.memberCount) 成员 · 周活跃 \(circle.weeklyActive)")
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.tertiary)
            }
        } icon: {
            Image(systemName: circle.systemImage)
                .foregroundStyle(.tint)
        }
    }
}

// MARK: - Buddies hub (陪玩预约 + 活动邀约)

/// 「我的陪玩」：陪玩预约与活动邀约同一入口，分段切换。
struct ProfileBuddiesView: View {
    private enum Segment: String, CaseIterable, Identifiable {
        case bookings = "陪玩预约"
        case invites = "活动邀约"

        var id: String { rawValue }
    }

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @State private var segment: Segment = .bookings

    var body: some View {
        List {
            Section {
                Picker("我的陪玩", selection: $segment) {
                    ForEach(Segment.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text("管理陪玩预约与活动邀约。找新陪玩去「搭子」页，好友聊天在「消息」。")
            }

            switch segment {
            case .bookings:
                ProfileBookingCredentialsSection()
            case .invites:
                Section {
                    inviteRows
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .navigationTitle("我的陪玩")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .onAppear {
            if buddies.bookingRecords.isEmpty, !buddies.inviteRecords.isEmpty {
                segment = .invites
            }
        }
        .sheet(item: Binding(
            get: { buddies.pendingPaymentBooking },
            set: { if $0 == nil { buddies.cancelPendingPayment() } }
        )) { record in
            BookingPaymentSheet(
                record: record,
                onConfirm: { method in confirmBookingPayment(record, method: method) },
                onCancel: { buddies.cancelPendingPayment() }
            )
        }
        .sheet(item: Binding(
            get: { buddies.pendingSafetyCheckInBooking },
            set: { if $0 == nil { buddies.cancelPendingSafetyCheckIn() } }
        )) { record in
            TrustSafetyCheckInSheet(record: record) {
                buddies.cancelPendingSafetyCheckIn()
            }
        }
    }

    @ViewBuilder
    private var inviteRows: some View {
        if buddies.inviteRecords.isEmpty {
            ContentUnavailableView(
                "还没有活动邀约",
                systemImage: "paperplane",
                description: Text("在搭子页邀请同好参加活动后，记录会出现在这里。")
            )
        } else {
            ForEach(buddies.inviteRecords) { record in
                NavigationLink {
                    BuddyInviteDetailView(recordID: record.id)
                } label: {
                    ProfileInviteRow(record: record)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("删除", systemImage: "trash", role: .destructive) {
                        buddies.deleteInvite(record.id)
                    }
                    #if DEBUG
                    if record.status == .pending {
                        Button("模拟接受", systemImage: "checkmark") {
                            buddies.acceptInvite(record.id)
                        }
                        .tint(.green)
                        Button("模拟婉拒", systemImage: "xmark") {
                            buddies.declineInvite(record.id)
                        }
                        .tint(.orange)
                    }
                    #endif
                }
            }
        }
    }

    private func confirmBookingPayment(
        _ record: BuddyBookingRecord,
        method: PaymentMethod
    ) -> PaymentOutcome {
        let outcome = buddies.confirmPayment(record.id, method: method)
        guard outcome == .success else { return outcome }
        let greeting =
            "你好！我想预约 \(Formatters.monthDay.string(from: record.scheduledAt)) "
            + "\(Formatters.shortTime.string(from: record.scheduledAt)) 开始的 \(record.hours) 小时陪玩，方便确认一下吗？"
        if let convo = app.startDirectChat(with: record.companionNickname, greeting: greeting) {
            app.openMessages(conversationID: convo.id)
        }
        return .success
    }
}

private struct ProfileInviteRow: View {
    let record: BuddyInviteRecord

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text("邀请 \(record.nickname)")
                    .font(PlatformListTypography.primary)
                Spacer(minLength: 0)
                Text(record.status.rawValue)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(inviteStatusColor(record.status))
            }

            Text(record.activityTitle)
                .font(PlatformListTypography.secondary)
                .foregroundStyle(.secondary)

            Text(Formatters.activityDate.string(from: record.sentAt))
                .font(PlatformListTypography.footnote)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}
