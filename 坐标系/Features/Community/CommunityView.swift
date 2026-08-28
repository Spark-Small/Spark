//
//  CommunityView.swift
//  坐标系
//

import SwiftUI

/// 广场：活动图文分享流（种草 / 复盘），找人与陪玩在「搭子」页完成
struct CommunityView: View {
    @Environment(CommunityModel.self) private var model
    @State private var path = NavigationPath()
    @Namespace private var zoomNamespace

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            List {
                Section {
                    if model.items.isEmpty {
                        emptyState
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
            .platformTabRootListChrome(title: CommunityCopy.rootTitle)
            .platformTabRootToolbar { tabToolbar }
            .tint(PlatformAction.cloverPurple)
            .navigationDestination(for: CommunityPost.self) { post in
                CommunityPostDetailView(postID: post.id)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .navigationDestination(for: CommunityLibraryDestination.self) { destination in
                CommunityLibraryRouter(destination: destination)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $model.isComposing) {
                CommunityComposeSheet()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }

    @ToolbarContentBuilder
    private var tabToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("发分享", systemImage: "plus") {
                model.isComposing = true
            }

            Menu {
                Button("收藏", systemImage: "bookmark") {
                    path.append(CommunityLibraryDestination.bookmarks)
                }
                Button("赞过", systemImage: "heart") {
                    path.append(CommunityLibraryDestination.liked)
                }
                Button("我的分享", systemImage: "square.and.pencil") {
                    path.append(CommunityLibraryDestination.myPosts)
                }
                Button("转发", systemImage: "arrow.2.squarepath") {
                    path.append(CommunityLibraryDestination.reposts)
                }
                Divider()
                Button("社区公约", systemImage: "doc.text") {
                    path.append(CommunityLibraryDestination.guidelines)
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("更多")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有分享", systemImage: "photo.on.rectangle")
        } description: {
            Text("把好玩的局、路线和探店记下来，让更多人看见")
        } actions: {
            Button("发分享") { model.isComposing = true }
                .activityPrimaryCTA(controlSize: .large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }
}

#Preview("广场") {
    CommunityView()
        .environment(CommunityModel())
        .environment(ActivitiesModel())
}
