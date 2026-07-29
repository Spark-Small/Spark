//
//  ProfileSocialViews.swift
//  坐标系
//

import SwiftUI

// MARK: - Activities

enum ProfileActivityListKind {
    case joined
    case hosted
    case favorites
}

struct ProfileActivitiesListView: View {
    let title: String
    let kind: ProfileActivityListKind
    let emptyTitle: String
    let emptyDescription: String

    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app

    private var liveActivities: [Activity] {
        switch kind {
        case .joined: activities.joinedActivities
        case .hosted: activities.hostedActivities
        case .favorites: activities.favoriteActivities
        }
    }

    var body: some View {
        List {
            if liveActivities.isEmpty {
                ContentUnavailableView(emptyTitle, systemImage: "calendar", description: Text(emptyDescription))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(liveActivities) { activity in
                    NavigationLink(value: activity) {
                        ProfileActivityRow(activity: activity)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        switch kind {
                        case .joined:
                            Button("取消报名", systemImage: "ticket") {
                                if ActivityPaymentStore.hasPaid(for: activity.id) {
                                    app.cancelActivityRegistration(activity.id, refundIfPaid: true)
                                } else {
                                    app.cancelActivityRegistration(activity.id)
                                }
                            }
                            .tint(.orange)
                        case .favorites:
                            Button("取消收藏", systemImage: "bookmark.slash") {
                                activities.toggleFavorite(activity.id)
                            }
                            .tint(.gray)
                        case .hosted:
                            Button("编辑", systemImage: "pencil") {
                                app.beginEditActivity(activity.id)
                            }
                            .tint(.blue)
                            Button(ActivityDetailCopy.hostManageCancelActivity, systemImage: "trash", role: .destructive) {
                                app.cancelHostedActivity(activity.id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .navigationDestination(for: Activity.self) { activity in
            ActivityDetailView(activity: activity)
        }
    }
}

private struct ProfileActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.category.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(activity.fee)
                        .font(.caption2)
                        .foregroundStyle(activity.isFree ? PlatformStatus.success : .secondary)

                    if activity.isPast {
                        Text("已结束")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, PlatformMetrics.hairlineSpacing)
    }
}

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
        .navigationDestination(for: InterestCircle.self) { circle in
            ProfileCircleDetailView(circle: circle)
        }
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
        .navigationDestination(for: InterestCircle.self) { circle in
            ProfileCircleDetailView(circle: circle)
        }
    }
}

private struct ProfileCircleRow: View {
    let circle: InterestCircle
    var isJoined: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: circle.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(circle.name)
                        .font(.body)
                        .fontWeight(.medium)
                    if isJoined {
                        Text("已加入")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(PlatformStatus.success)
                    }
                }

                Text("\(circle.city) · \(circle.topic)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(circle.memberCount) 成员 · 周活跃 \(circle.weeklyActive)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, PlatformMetrics.hairlineSpacing)
    }
}

// MARK: - Nearby buddies

struct ProfileNearbyBuddiesView: View {
    private var nearbyItems: [DiscoverBuddyItem] {
        var filter = BuddyFilter()
        filter.maxDistanceKM = 5
        return (SampleData.circleBuddies.map(DiscoverBuddyItem.free)
            + SampleData.paidCompanions.map(DiscoverBuddyItem.paid))
            .filter { $0.profile.matches(filter) }
            .sorted { $0.profile.distanceKM < $1.profile.distanceKM }
    }

    var body: some View {
        List {
            if nearbyItems.isEmpty {
                ContentUnavailableView(
                    "附近暂无同好",
                    systemImage: "person.2.slash",
                    description: Text("调整筛选条件或稍后再来看看。")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(nearbyItems) { item in
                    NavigationLink(value: item) {
                        ProfileNearbyBuddyRow(profile: item.profile, isOnline: item.isOnline)
                    }
                }
            }
        }
        .navigationTitle("附近同好")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .navigationDestination(for: DiscoverBuddyItem.self) { item in
            BuddyDetailRouteView(item: item)
        }
    }
}

private struct ProfileNearbyBuddyRow: View {
    let profile: BuddyProfile
    var isOnline: Bool

    var body: some View {
        HStack(spacing: 12) {
            HeroPersonCover(name: profile.nickname, photos: profile.photoRefs)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(profile.nickname)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(profile.gender.symbol)
                        .font(.caption)
                        .foregroundStyle(profile.gender.tint)
                    if isOnline {
                        Text("在线")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(PlatformStatus.success)
                    }
                }

                Text(profile.lookingFor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(profile.distanceText) · \(profile.age)岁")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, PlatformMetrics.hairlineSpacing)
    }
}

// MARK: - Booking records

struct ProfileBookingRecordsView: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            if buddies.bookingRecords.isEmpty {
                ContentUnavailableView(
                    "还没有预约记录",
                    systemImage: "person.badge.clock",
                    description: Text("在搭子页找到陪玩后，可以预约并在这里查看。")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(buddies.bookingRecords) { record in
                    NavigationLink {
                        BuddyBookingDetailView(recordID: record.id)
                    } label: {
                        ProfileBookingRowContent(record: record)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("删除", systemImage: "trash", role: .destructive) {
                            buddies.deleteBooking(record.id)
                        }
                        if record.canPay {
                            Button("去支付", systemImage: "yensign.circle") {
                                buddies.beginPayment(record.id)
                            }
                            .tint(.green)
                        }
                        if record.canSimulateCounterpart {
                            Button("模拟接单", systemImage: "hand.thumbsup") {
                                buddies.acceptBooking(record.id)
                            }
                            .tint(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("预约过的陪玩")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .sheet(item: Binding(
            get: { buddies.pendingPaymentBooking },
            set: { if $0 == nil { buddies.cancelPendingPayment() } }
        )) { record in
            BookingPaymentSheet(
                record: record,
                onConfirm: {
                    buddies.confirmPayment(record.id)
                    let greeting =
                        "你好！我想预约 \(Formatters.monthDay.string(from: record.scheduledAt)) "
                        + "\(Formatters.shortTime.string(from: record.scheduledAt)) 开始的 \(record.hours) 小时陪玩，方便确认一下吗？"
                    if let convo = app.startDirectChat(
                        with: record.companionNickname,
                        greeting: greeting
                    ) {
                        app.openMessages(conversationID: convo.id)
                    }
                },
                onCancel: {
                    buddies.cancelPendingPayment()
                }
            )
        }
    }
}

private struct ProfileBookingRowContent: View {
    let record: BuddyBookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.companionNickname)
                    .font(.headline)
                Spacer()
                Text(record.statusLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(bookingStatusColor(record.status))
                Text(record.priceText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(PlatformStatus.warning)
            }

            Label(
                "\(Formatters.monthDay.string(from: record.scheduledAt)) \(Formatters.shortTime.string(from: record.scheduledAt)) · \(record.hours) 小时",
                systemImage: "clock"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text("预约于 \(Formatters.activityDate.string(from: record.bookedAt))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Invite records

struct ProfileInviteRecordsView: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            if buddies.inviteRecords.isEmpty {
                ContentUnavailableView(
                    "还没有发出过邀约",
                    systemImage: "paperplane",
                    description: Text("在搭子页邀请同好参加活动后，记录会出现在这里。")
                )
                .listRowBackground(Color.clear)
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
                    }
                }
            }
        }
        .navigationTitle("邀请记录")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

private struct ProfileInviteRow: View {
    let record: BuddyInviteRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("邀请 \(record.nickname)")
                    .font(.headline)
                Spacer()
                Text(record.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(inviteStatusColor(record.status))
            }

            Label(record.activityTitle, systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Formatters.activityDate.string(from: record.sentAt))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
        .accessibilityElement(children: .combine)
    }
}

