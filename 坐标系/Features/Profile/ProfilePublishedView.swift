//
//  ProfilePublishedView.swift
//  坐标系
//
//  「我的发布」：本机社区分享 + 发起活动，可从「我的」直接查看。
//

import SwiftUI

struct ProfilePublishedView: View {
    enum Segment: String, CaseIterable, Identifiable, Hashable {
        case posts = "分享"
        case activities = "活动"

        var id: String { rawValue }
    }

    @Environment(ActivitiesModel.self) private var activities
    @Environment(CommunityModel.self) private var community
    @State private var segment: Segment = .posts

    init(initialSegment: Segment = .posts) {
        _segment = State(initialValue: initialSegment)
    }

    private var snapshot: CreatorInsightsSnapshot {
        CreatorInsightsService.snapshot(activities: activities, community: community)
    }

    var body: some View {
        List {
            Section {
                Picker("我的发布", selection: $segment) {
                    ForEach(Segment.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text("查看你发过的社区分享与发起活动。互动数据基于本机统计。")
            }

            Section {
                switch segment {
                case .posts:
                    postsRows
                case .activities:
                    activitiesRows
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .navigationTitle("我的发布")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .navigationDestination(for: CommunityPost.self) { post in
            CommunityPostDetailView(postID: post.id)
        }
        .navigationDestination(for: Activity.self) { activity in
            ActivityDetailView(activity: activity)
        }
        .onAppear {
            if snapshot.posts.isEmpty, !snapshot.activities.isEmpty {
                segment = .activities
            }
        }
    }

    @ViewBuilder
    private var postsRows: some View {
        let items = snapshot.posts
        if items.isEmpty {
            ContentUnavailableView(
                "还没有发布分享",
                systemImage: "square.and.pencil",
                description: Text("在社区发帖后，内容会出现在这里。")
            )
        } else {
            ForEach(items) { item in
                NavigationLink(value: item.post) {
                    PlatformListTextColumn(
                        primary: item.post.messageText,
                        secondary: Formatters.conversationListTime(from: item.post.postedAt),
                        footnote: item.metricLine,
                        primaryLineLimit: 3
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var activitiesRows: some View {
        let items = snapshot.activities
        if items.isEmpty {
            ContentUnavailableView(
                "还没有发起活动",
                systemImage: "flag",
                description: Text("发起活动后，会出现在这里，也可在「我的活动」里管理。")
            )
        } else {
            ForEach(items) { item in
                NavigationLink(value: item.activity) {
                    PlatformListTextColumn(
                        primary: item.activity.title,
                        secondary: Formatters.activityEventTime(from: item.activity.date),
                        footnote: item.metricLine
                    )
                }
            }
        }
    }
}
