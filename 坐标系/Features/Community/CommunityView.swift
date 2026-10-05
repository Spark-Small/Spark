//
//  CommunityView.swift
//  坐标系
//
//  广场 Tab / 内嵌栈根；Feed / 动态区 / 工具栏见同模块扩展（无顶栏搜索）。
//

import SwiftUI
import UserNotifications
import CoordinateModels

enum CommunityFeedPresentation {
    case tabRoot
    case embedded
}

/// 广场信息流（Tab 根或从活动 Tab push）。
struct CommunityFeedStack: View {
    var presentation: CommunityFeedPresentation = .tabRoot
    var zoomNamespace: Namespace.ID
    /// 活动 Tab 内嵌时由父栈注册 `CommunityPost` / Zoom，避免嵌套 NavigationStack。
    var registersStackDestinations = true

    @Environment(CommunityModel.self) var model
    @Environment(AppModel.self) var app
    @Environment(ActivitiesModel.self) var activities
    @Environment(InAppNotificationStore.self) var notificationInbox

    @State var feedFilter: CommunityFeedFilter = .all
    @State var feedPreferences = CommunityFeedPreferences()
    @State var notificationAuth: UNAuthorizationStatus = .notDetermined
    /// 「发现作者」下本会话刚关注的作者：帖保留至离开该筛选。
    @State var sessionRetainedDiscoverAuthors: Set<String> = []
    /// 「全部」推荐置顶：固定本会话卡片，关注后只改按钮不换帖。
    @State var pinnedRecommendationID: CommunityPost.ID?

    var body: some View {
        @Bindable var model = model

        List {
            Section {
                CommunityFeedFilterBar(filter: $feedFilter)
                    .communityFeedFilterRowChrome()
            }

            if showsDynamicsRail, !showsFeedUnavailable {
                dynamicsSection
            }

            if !showsFeedUnavailable {
                Section {
                    feedPostsSection
                }
            }
        }
        .communityFeedChrome()
        .overlay {
            // 仅叠系统空态本体（固有尺寸居中）；勿铺满，以免挡住顶栏筛选点击。
            if showsFeedUnavailable {
                feedUnavailableOverlay
            }
        }
        .environment(\.communityRetainFollowedAuthor) { author in
            guard feedFilter == .peopleYouFollow else { return }
            sessionRetainedDiscoverAuthors.insert(author)
        }
        .onChange(of: feedFilter) { _, _ in
            sessionRetainedDiscoverAuthors = []
            pinnedRecommendationID = nil
        }
        .refreshable {
            await model.reloadFromRepository()
            await refreshNotificationAuth()
            await notificationInbox.syncDeliveredFromSystem()
        }
        .modifier(CommunityFeedPresentationChrome(presentation: presentation))
        .communityFeedToolbar(presentation: presentation) { feedToolbar }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsNotifyBanner {
                CommunityNotificationsOffBanner(
                    onTurnOn: { Task { await turnOnNotifications() } },
                    onDismiss: { feedPreferences.dismissNotifyBanner() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            if model.loadErrorMessage == nil {
                await model.reloadFromRepository()
            }
            await refreshNotificationAuth()
        }
        .platformFeedbackAlert(
            Binding(
                get: { model.presentation.toastMessage },
                set: { model.presentation.toastMessage = $0 }
            )
        )
        .modifier(
            CommunityFeedStackDestinationsModifier(
                enabled: registersStackDestinations,
                zoomNamespace: zoomNamespace
            )
        )
        .sheet(
            isPresented: $model.presentation.isComposing,
            onDismiss: { model.presentation.endCompose() }
        ) {
            CommunityComposeSheet()
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}

private struct CommunityFeedStackDestinationsModifier: ViewModifier {
    let enabled: Bool
    let zoomNamespace: Namespace.ID

    func body(content: Content) -> some View {
        if enabled {
            content
                .navigationDestination(for: CommunityPost.self) { post in
                    CommunityPostDetailView(postID: post.id)
                        .toolbarVisibility(.hidden, for: .tabBar)
                }
                .navigationDestination(for: CommunityLibraryDestination.self) { destination in
                    CommunityLibraryRouter(destination: destination)
                        .toolbarVisibility(.hidden, for: .tabBar)
                }
                .activityZoomNavigationDestination(namespace: zoomNamespace)
        } else {
            content
        }
    }
}

private struct CommunityFeedPresentationChrome: ViewModifier {
    let presentation: CommunityFeedPresentation

    func body(content: Content) -> some View {
        switch presentation {
        case .tabRoot:
            content.platformTabRootListChrome(title: CommunityBrowseCopy.rootTitle)
        case .embedded:
            content
                .navigationTitle(CommunityBrowseCopy.embeddedTitle)
                .navigationBarTitleDisplayMode(.inline)
                .platformHiddenTabBar()
        }
    }
}

extension View {
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

/// 消费 `pendingCommunityPostID`，推进到帖详情；缺帖时先 reload 再试，仍无则清空避免挂死。
struct CommunityPendingPostNavigationModifier: ViewModifier {
    @Binding var path: NavigationPath
    /// 活动 Tab 软启动栈：先重置 path，避免叠在详情 / 最近看过之上。
    var resetPathBeforeAppend = false
    var onBeforeAppend: (() -> Void)?

    @Environment(AppModel.self) private var app
    @Environment(CommunityModel.self) private var community

    func body(content: Content) -> some View {
        content
            .onAppear(perform: consume)
            .onChange(of: app.pendingCommunityPostID) { _, _ in
                consume()
            }
    }

    private func appendPost(_ post: CommunityPost) {
        onBeforeAppend?()
        if resetPathBeforeAppend {
            path = NavigationPath()
        }
        path.append(post)
    }

    private func consume() {
        guard let id = app.pendingCommunityPostID else { return }
        if let post = community.post(id: id) {
            app.pendingCommunityPostID = nil
            appendPost(post)
            return
        }
        Task {
            await community.reloadFromRepository()
            await MainActor.run {
                guard app.pendingCommunityPostID == id else { return }
                if let post = community.post(id: id) {
                    app.pendingCommunityPostID = nil
                    appendPost(post)
                } else {
                    app.pendingCommunityPostID = nil
                }
            }
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
                zoomNamespace: zoomNamespace
            )
        }
        .modifier(CommunityPendingPostNavigationModifier(path: $path))
    }
}

#Preview("广场") {
    let app = AppModel.preview
    CommunityView()
        .environment(app)
        .environment(app.community)
        .environment(app.activities)
        .environment(app.buddies)
        .environment(app.inAppNotificationStore)
}
