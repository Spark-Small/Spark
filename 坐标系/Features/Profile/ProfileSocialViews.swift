//
//  ProfileSocialViews.swift
//  坐标系
//
//  「我的」二级页：收藏、圈子、我的陪玩（陪玩预约 + 活动邀约）。
//

import SwiftUI

// MARK: - Favorites

struct ProfileFavoritesView: View {
    private enum Segment: String, CaseIterable, Identifiable {
        case activities = "活动"
        case posts = "分享"

        var id: String { rawValue }
    }

    @Environment(ActivitiesModel.self) private var activities
    @Environment(CommunityModel.self) private var community
    @State private var segment: Segment = .activities

    var body: some View {
        List {
            Section {
                Picker("收藏", selection: $segment) {
                    ForEach(Segment.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                switch segment {
                case .activities: favoriteActivitiesRows
                case .posts: favoritePostsRows
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .navigationTitle("收藏")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .navigationDestination(for: Activity.self) { activity in
            ActivityDetailView(activity: activity)
        }
        .navigationDestination(for: CommunityPost.self) { post in
            CommunityPostDetailView(postID: post.id)
        }
    }

    @ViewBuilder
    private var favoriteActivitiesRows: some View {
        let items = activities.favoriteActivities
        if items.isEmpty {
            ContentUnavailableView(
                "还没有收藏活动",
                systemImage: "calendar",
                description: Text("在活动详情里点收藏，想去的局会出现在这里。")
            )
        } else {
            ForEach(items) { activity in
                NavigationLink(value: activity) {
                    ProfileActivityRow(activity: activity)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("取消收藏", systemImage: "bookmark.slash") {
                        activities.toggleFavorite(activity.id)
                    }
                    .tint(.gray)
                }
            }
        }
    }

    @ViewBuilder
    private var favoritePostsRows: some View {
        let items = community.bookmarkedPosts
        if items.isEmpty {
            ContentUnavailableView(
                "还没有收藏分享",
                systemImage: "photo.on.rectangle",
                description: Text("在社区分享里点收藏，种草与复盘会出现在这里。")
            )
        } else {
            ForEach(items) { post in
                NavigationLink(value: post) {
                    PlatformListTextColumn(
                        primary: post.messageText,
                        secondary: postLibrarySecondary(for: post),
                        footnote: community.bookmarkCollection(for: post.id),
                        primaryLineLimit: 2
                    )
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("取消收藏", systemImage: "bookmark.slash") {
                        community.removeBookmark(post.id)
                    }
                    .tint(.gray)
                }
            }
        }
    }

    private func postLibrarySecondary(for post: CommunityPost) -> String {
        let time = Formatters.conversationListTime(from: post.postedAt)
        if post.author.isEmpty { return time }
        return "\(post.author) · \(time)"
    }
}

private struct ProfileActivityRow: View {
    let activity: Activity

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(activity.title)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)
                Text("\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)")
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(activity.fee)
                        .font(PlatformListTypography.footnote)
                        .foregroundStyle(activity.isFree ? PlatformStatus.success : .secondary)
                    if activity.isPast {
                        Text("已结束")
                            .font(PlatformListTypography.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } icon: {
            Image(systemName: activity.category.systemImage)
                .foregroundStyle(.tint)
        }
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

            Section {
                switch segment {
                case .bookings:
                    bookingRows
                case .invites:
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
                onConfirm: { confirmBookingPayment(record) },
                onCancel: { buddies.cancelPendingPayment() }
            )
        }
    }

    @ViewBuilder
    private var bookingRows: some View {
        if buddies.bookingRecords.isEmpty {
            ContentUnavailableView(
                "还没有陪玩预约",
                systemImage: "person.badge.clock",
                description: Text("在搭子页预约陪玩后，订单会出现在这里。")
            )
        } else {
            ForEach(buddies.bookingRecords) { record in
                NavigationLink {
                    BuddyBookingDetailView(recordID: record.id)
                } label: {
                    ProfileBookingRow(record: record)
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
                    #if DEBUG
                    if record.canSimulateCounterpart {
                        Button("模拟接单", systemImage: "hand.thumbsup") {
                            buddies.acceptBooking(record.id)
                        }
                        .tint(.green)
                    }
                    #endif
                }
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

    private func confirmBookingPayment(_ record: BuddyBookingRecord) {
        buddies.confirmPayment(record.id)
        let greeting =
            "你好！我想预约 \(Formatters.monthDay.string(from: record.scheduledAt)) "
            + "\(Formatters.shortTime.string(from: record.scheduledAt)) 开始的 \(record.hours) 小时陪玩，方便确认一下吗？"
        if let convo = app.startDirectChat(with: record.companionNickname, greeting: greeting) {
            app.openMessages(conversationID: convo.id)
        }
    }
}

private struct ProfileBookingRow: View {
    let record: BuddyBookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(record.companionNickname)
                    .font(PlatformListTypography.primary)
                Spacer(minLength: 0)
                Text(record.statusLabel)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(bookingStatusColor(record.status))
                Text(record.priceText)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(PlatformStatus.warning)
            }

            Text(
                "\(Formatters.monthDay.string(from: record.scheduledAt)) \(Formatters.shortTime.string(from: record.scheduledAt)) · \(record.hours) 小时"
            )
            .font(PlatformListTypography.secondary)
            .foregroundStyle(.secondary)

            Text("预约于 \(Formatters.activityDate.string(from: record.bookedAt))")
                .font(PlatformListTypography.footnote)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
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
