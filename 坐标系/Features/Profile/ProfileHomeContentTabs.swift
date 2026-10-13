//
//  ProfileHomeContentTabs.swift
//  坐标系
//
//  「我的」主页内容四档：发帖 / 活动 / 陪玩 / 俱乐部页内直展。
//  空态在档条下、随 Scroll 滚（官方社交主页口径；非 Scroll overlay 钉死）。
//

import CoordinateModels
import SwiftUI

enum ProfileHomeContentTab: String, CaseIterable, Identifiable, Hashable {
    case posts
    case activities
    case companions
    case clubs

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .posts: ProfileHomeContentCopy.postsTab
        case .activities: ProfileHomeContentCopy.activitiesTab
        case .companions: ProfileHomeContentCopy.companionsTab
        case .clubs: ProfileHomeContentCopy.clubsTab
        }
    }

    var systemImage: String {
        switch self {
        case .posts: "square.grid.3x3"
        case .activities: "calendar"
        case .companions: "person.2.fill"
        case .clubs: "person.3.fill"
        }
    }

    /// 深链库路由 → 主页四档。
    init?(profileRoute: ProfileRoute) {
        switch profileRoute {
        case .myPosts: self = .posts
        case .activitiesLibrary: self = .activities
        case .bookingCredentials: self = .companions
        case .myClubs: self = .clubs
        default: return nil
        }
    }
}

enum ProfileHomeContentCopy {
    static let postsTab = "发帖"
    static let activitiesTab = "活动"
    static let companionsTab = "陪玩"
    static let clubsTab = "俱乐部"
    static let emptyTitle = "这里空荡荡～"
    static let emptyPostsHint = "你发布的帖子会出现在这里"
    static let emptyActivitiesHint = "参加或发起活动后会出现在这里"
    static let emptyCompanionsHint = "预约陪玩后凭证会出现在这里"
    static let emptyClubsHint = "加入俱乐部后会出现在这里"
    static let textPostPlaceholder = "文字帖"
}

/// 四档可见供给（空态与嵌体共用，避免判定分叉）。
@MainActor
enum ProfileHomeTabContent {
    static func posts(from community: CommunityModel) -> [CommunityPost] {
        (community.myPosts + community.myReposts)
            .sorted { $0.postedAt > $1.postedAt }
    }

    /// 空态判定勿整表 sort（Scroll 体重绘时会放大开销）。
    static func isPostsEmpty(from community: CommunityModel) -> Bool {
        community.myPosts.isEmpty && community.myReposts.isEmpty
    }

    static func activities(from activities: ActivitiesModel) -> [Activity] {
        var byID: [Activity.ID: Activity] = [:]
        for activity in activities.joinedActivities { byID[activity.id] = activity }
        for activity in activities.waitlistedActivities { byID[activity.id] = activity }
        for activity in activities.hostedActivities { byID[activity.id] = activity }
        return Array(byID.values).sorted { lhs, rhs in
            if lhs.isPast != rhs.isPast { return !lhs.isPast && rhs.isPast }
            return lhs.date < rhs.date
        }
    }

    static func isActivitiesEmpty(from activities: ActivitiesModel) -> Bool {
        activities.joinedActivities.isEmpty
            && activities.waitlistedActivities.isEmpty
            && activities.hostedActivities.isEmpty
    }

    static func companions(from buddies: BuddiesModel) -> [BuddyBookingRecord] {
        buddies.bookingRecords.sorted { $0.scheduledAt > $1.scheduledAt }
    }

    static func isCompanionsEmpty(from buddies: BuddiesModel) -> Bool {
        buddies.bookingRecords.isEmpty
    }

    static func clubs(from buddies: BuddiesModel) -> [InterestCircle] {
        buddies.membershipClubs
    }

    static func isClubsEmpty(from buddies: BuddiesModel) -> Bool {
        buddies.membershipClubs.isEmpty
    }
}

struct ProfileHomeContentTabs: View {
    @Binding var selection: ProfileHomeContentTab
    var activityZoomNamespace: Namespace.ID

    @Environment(CommunityModel.self) private var community
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            if isSelectedTabEmpty {
                ProfileHomeTabEmptyRegion(selection: selection)
            } else {
                tabBody
            }
        }
    }

    private var isSelectedTabEmpty: Bool {
        switch selection {
        case .posts: ProfileHomeTabContent.isPostsEmpty(from: community)
        case .activities: ProfileHomeTabContent.isActivitiesEmpty(from: activities)
        case .companions: ProfileHomeTabContent.isCompanionsEmpty(from: buddies)
        case .clubs: ProfileHomeTabContent.isClubsEmpty(from: buddies)
        }
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ProfileHomeContentTab.allCases) { tab in
                    Button {
                        selection = tab
                    } label: {
                        Image(systemName: tab.systemImage)
                            .font(PlatformListTypography.body)
                            .fontWeight(selection == tab ? .semibold : .regular)
                            .foregroundStyle(selection == tab ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PlatformConversationListRow.verticalInset)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(selection == tab ? Color.primary : .clear)
                                    .frame(height: PlatformMetrics.separatorHairline)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.shortTitle)
                    .accessibilityAddTraits(selection == tab ? .isSelected : [])
                }
            }
            Divider()
        }
        .discoverBrowseContentInset()
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var tabBody: some View {
        switch selection {
        case .posts:
            ProfileHomePostsGrid()
        case .activities:
            ProfileHomeActivitiesEmbed(zoomNamespace: activityZoomNamespace)
        case .companions:
            ProfileHomeCompanionsEmbed()
        case .clubs:
            ProfileHomeClubsEmbed()
        }
    }
}

/// 「我的」四档空态：档条下随 Scroll 滚；相对视口撑高后系统居中（非 overlay 钉死）。
struct ProfileHomeTabEmptyRegion: View {
    let selection: ProfileHomeContentTab

    @Environment(CommunityModel.self) private var community
    @Environment(AppModel.self) private var app

    var body: some View {
        emptyChrome
            .platformScrollEmbeddedEmptyChrome()
    }

    @ViewBuilder
    private var emptyChrome: some View {
        switch selection {
        case .posts:
            ProfileLibraryEmptyView(
                title: ProfileHomeContentCopy.emptyTitle,
                systemImage: "camera",
                description: ProfileHomeContentCopy.emptyPostsHint
            ) {
                Button(ProfileMyPostsCopy.composeAction) {
                    community.beginCompose()
                }
                Button(ProfileMyPostsCopy.browseCommunity) {
                    app.selectedTab = .community
                }
            }
        case .activities:
            ProfileLibraryEmptyView(
                title: ProfileHomeContentCopy.emptyTitle,
                systemImage: "calendar",
                description: ProfileHomeContentCopy.emptyActivitiesHint
            ) {
                Button(ProfileMyActivitiesCopy.browseDiscover) {
                    app.focusActivitiesDiscoverBrowse()
                }
            }
        case .companions:
            ProfileLibraryEmptyView(
                title: ProfileHomeContentCopy.emptyTitle,
                systemImage: "person.2.fill",
                description: ProfileHomeContentCopy.emptyCompanionsHint
            ) {
                Button(ProfileMyCompanionsCopy.browseDiscover) {
                    app.pendingBuddiesRoute = .paidBrowse
                    app.selectedTab = .buddies
                }
            }
        case .clubs:
            ProfileLibraryEmptyView(
                title: ProfileHomeContentCopy.emptyTitle,
                systemImage: "person.3.fill",
                description: ProfileHomeContentCopy.emptyClubsHint
            ) {
                Button(ProfileMyClubsCopy.browseDiscover) {
                    app.pendingBuddiesRoute = .clubDiscover
                    app.selectedTab = .buddies
                }
            }
        }
    }
}
