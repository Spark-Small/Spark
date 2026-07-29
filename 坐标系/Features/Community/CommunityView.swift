//
//  CommunityView.swift
//  坐标系
//

import SwiftUI

/// 社区：活动图文分享流（种草 / 复盘），找人与陪玩在「搭子」页完成
struct CommunityView: View {
    @Environment(AppModel.self) private var app
    @Environment(CommunityModel.self) private var model
    @Environment(MessagesModel.self) private var messages
    @Environment(BuddiesModel.self) private var buddies
    @State private var path = NavigationPath()

    private var feedChannels: [CommunityFeedChannel] {
        CommunityFeedChannelCatalog.channels(
            interests: app.user.interests,
            messages: messages,
            buddies: buddies,
            blockedNames: app.blockedUserNames
        )
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            List {
                Section {
                    CommunityFeedChannelRail(
                        channels: feedChannels,
                        selectedKind: model.selectedChannel,
                        onSelect: model.selectChannel
                    )
                    .communityFeedChannelRowChrome()

                    if model.items.isEmpty {
                        feedEmptyState
                            .communityFeedRowChrome()
                    } else {
                        ForEach(model.items) { post in
                            CommunityPostCard(post: post)
                                .communityFeedRowChrome()
                        }
                    }
                }
            }
            .communityFeedChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { feedToolbar }
            .navigationDestination(for: CommunityPost.self) { post in
                CommunityPostDetailView(postID: post.id)
            }
            .navigationDestination(for: Activity.self) { activity in
                ActivityDetailView(activity: activity)
            }
            .navigationDestination(for: CommunityLibraryDestination.self) { destination in
                CommunityLibraryRouter(destination: destination)
            }
            .sheet(isPresented: $model.isComposing) {
                CommunityComposeSheet()
            }
            .platformTabBarHiddenWhenPushed(path.isEmpty)
        }
    }

    @ViewBuilder
    private var feedEmptyState: some View {
        if model.isEmptyChannel {
            channelEmptyState
        } else {
            emptyState
        }
    }

    @ToolbarContentBuilder
    private var feedToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button("收藏", systemImage: "bookmark") {
                    path.append(CommunityLibraryDestination.bookmarks)
                }
                Button("赞过的", systemImage: "heart") {
                    path.append(CommunityLibraryDestination.liked)
                }
                Button("我的分享", systemImage: "square.and.pencil") {
                    path.append(CommunityLibraryDestination.myPosts)
                }
                Button("我的转发", systemImage: "arrow.2.squarepath") {
                    path.append(CommunityLibraryDestination.reposts)
                }
                Divider()
                Button("社区公约", systemImage: "doc.text") {
                    path.append(CommunityLibraryDestination.guidelines)
                }
            } label: {
                Label("更多", systemImage: "line.3.horizontal")
            }
            .accessibilityLabel("更多")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("发分享", systemImage: "plus") {
                model.isComposing = true
            }
        }
    }

    private var channelEmptyState: some View {
        let title = channelEmptyTitle
        return ContentUnavailableView {
            Label(title, systemImage: "person.2")
        } description: {
            Text("这个频道还没有相关分享，试试其他频道或发一条吧")
        } actions: {
            Button("查看全部") {
                model.selectChannel(.all)
            }
            .buttonStyle(.bordered)
        }
    }

    private var channelEmptyTitle: String {
        switch model.selectedChannel {
        case .all: "暂无分享"
        case .friend(let name): "\(messages.displayName(for: name)) 暂无分享"
        case .interest(let tag): "「\(tag)」暂无分享"
        case .group(_, let title, _, _): "「\(title)」暂无分享"
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有分享", systemImage: "photo.on.rectangle")
        } description: {
            Text("把好玩的局、路线和探店记下来，让更多人看见")
        } actions: {
            Button("发分享") { model.isComposing = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("社区") {
    CommunityView()
        .environment(AppModel())
        .environment(CommunityModel())
        .environment(MessagesModel())
        .environment(ActivitiesModel())
        .environment(BuddiesModel())
}
