//
//  ProfilePublishedView.swift
//  坐标系
//
//  「我的发布」：创作凭证列表（分享 / 发起活动），不进系统 Wallet。
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
    @Namespace private var zoomNamespace
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
                Text("创作凭证仅在 App 内展示，不会加入 Apple Wallet。互动数据基于本机统计。")
            }

            Section {
                switch segment {
                case .posts:
                    postsRows
                case .activities:
                    activitiesRows
                }
            } header: {
                Text(segment == .posts ? "分享凭证夹" : "发起凭证夹")
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .navigationTitle("我的发布")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .activityZoomNavigationDestinationIfNeeded(fallback: zoomNamespace)
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
            .listRowBackground(Color.clear)
        } else {
            ForEach(items) { item in
                NavigationLink(value: item.post) {
                    ProfilePublishedCredentialCard(
                        kind: .post,
                        title: item.post.messageText,
                        metaLine: "\(ProfileLibraryCopy.postMetaLine(for: item.post)) · \(item.metricLine)",
                        photo: item.post.coverPhoto,
                        idHint: item.post.id.uuidString
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
            .listRowBackground(Color.clear)
        } else {
            ForEach(items) { item in
                ActivityZoomNavigationLink(
                    activity: item.activity,
                    namespace: zoomNamespace
                ) {
                    ProfilePublishedCredentialCard(
                        kind: .hostedActivity,
                        title: item.activity.title,
                        metaLine: "\(Formatters.activityEventTime(from: item.activity.date)) · \(item.metricLine)",
                        photo: item.activity.coverPhoto,
                        idHint: item.activity.id.uuidString
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }
}
