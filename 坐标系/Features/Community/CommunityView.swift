//
//  CommunityView.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

enum CommunityFeedPresentation {
    case tabRoot
    case embedded
}

/// 广场信息流（Tab 根或从活动 Tab push）。
struct CommunityFeedStack: View {
    var presentation: CommunityFeedPresentation = .tabRoot
    @Binding var path: NavigationPath
    var zoomNamespace: Namespace.ID

    @Environment(CommunityModel.self) private var model

    var body: some View {
        @Bindable var model = model

        List {
            Section {
                if let error = model.loadErrorMessage, model.items.isEmpty {
                    errorState(message: error)
                        .communityFeedRowChrome()
                } else if model.items.isEmpty {
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
        .refreshable {
            await model.reloadFromRepository()
        }
        .modifier(CommunityFeedPresentationChrome(presentation: presentation))
        .communityFeedToolbar(presentation: presentation) { feedToolbar }
        .tint(PlatformAction.cloverPurple)
        .task {
            // 首次进入时再拉一次，便于区分空列表与加载失败。
            if model.loadErrorMessage == nil {
                await model.reloadFromRepository()
            }
        }
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

    @ToolbarContentBuilder
    private var feedToolbar: some ToolbarContent {
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
            Label(CommunityCopy.emptyTitle, systemImage: "photo.on.rectangle")
        } description: {
            Text(CommunityCopy.emptyDescription)
        } actions: {
            Button("发分享") { model.isComposing = true }
                .activityPrimaryCTA(controlSize: .large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }

    private func errorState(message: String) -> some View {
        ContentUnavailableView {
            Label(CommunityCopy.loadFailedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button(CommunityCopy.retryLoad) {
                Task { await model.reloadFromRepository() }
            }
            .activityPrimaryCTA(controlSize: .large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }
}

private struct CommunityFeedPresentationChrome: ViewModifier {
    let presentation: CommunityFeedPresentation

    func body(content: Content) -> some View {
        switch presentation {
        case .tabRoot:
            content.platformTabRootListChrome(title: CommunityCopy.rootTitle)
        case .embedded:
            content
                .navigationTitle(CommunityCopy.embeddedTitle)
                .navigationBarTitleDisplayMode(.inline)
                .platformHiddenTabBar()
        }
    }
}

private extension View {
    @ViewBuilder
    func communityFeedToolbar(
        presentation: CommunityFeedPresentation,
        @ToolbarContentBuilder content: () -> some ToolbarContent
    ) -> some View {
        switch presentation {
        case .tabRoot:
            platformTabRootToolbar(content: content)
        case .embedded:
            toolbar(content: content)
        }
    }
}

/// 广场：活动图文分享流（种草 / 复盘），找人与陪玩在「搭子」页完成
struct CommunityView: View {
    @State private var path = NavigationPath()
    @Namespace private var zoomNamespace

    var body: some View {
        NavigationStack(path: $path) {
            CommunityFeedStack(
                presentation: .tabRoot,
                path: $path,
                zoomNamespace: zoomNamespace
            )
        }
    }
}

/// 活动 Tab 内嵌入口：安装 7 日且广场零打开时替代独立 Tab。
struct CommunityFeedEmbeddedDestination: View {
    @State private var path = NavigationPath()
    @Namespace private var zoomNamespace

    var body: some View {
        CommunityFeedStack(
            presentation: .embedded,
            path: $path,
            zoomNamespace: zoomNamespace
        )
    }
}

#Preview("广场") {
    let app = AppModel.preview
    CommunityView()
        .environment(app.community)
        .environment(app.activities)
}
