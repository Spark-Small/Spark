//
//  CommunityView.swift
//  坐标系
//
//  广场 Tab / 内嵌栈根；Feed / 动态区 / 工具栏 / 搜索见同模块扩展。
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

    @State var searchText = ""
    @State var feedFilter: CommunityFeedFilter = .all
    @State var feedPreferences = CommunityFeedPreferences()
    @State var notificationAuth: UNAuthorizationStatus = .notDetermined

    var body: some View {
        @Bindable var model = model

        List {
            Section {
                CommunityFeedFilterBar(filter: $feedFilter)
                    .communityFeedFilterRowChrome()
            }

            if showsDynamicsRail {
                dynamicsSection
            }

            Section {
                feedPostsSection
            }
        }
        .communityFeedChrome()
        // 搜索：系统托管；minimize 仅配合 bottomBar DefaultToolbarItem（见 +Toolbar）。
        .searchable(
            text: $searchText,
            prompt: CommunityBrowseCopy.searchPrompt
        )
        .searchSuggestions {
            communitySearchSuggestions
        }
        .searchToolbarBehavior(.minimize)
        .onSubmit(of: .search) {
            rememberCurrentSearchIfNeeded()
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
        .sheet(isPresented: $model.presentation.isComposing) {
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
    @Environment(AppModel.self) private var app
    @Environment(CommunityModel.self) private var community

    func body(content: Content) -> some View {
        content
            .onAppear(perform: consume)
            .onChange(of: app.pendingCommunityPostID) { _, _ in
                consume()
            }
    }

    private func consume() {
        guard let id = app.pendingCommunityPostID else { return }
        if let post = community.post(id: id) {
            app.pendingCommunityPostID = nil
            path.append(post)
            return
        }
        Task {
            await community.reloadFromRepository()
            await MainActor.run {
                guard app.pendingCommunityPostID == id else { return }
                if let post = community.post(id: id) {
                    app.pendingCommunityPostID = nil
                    path.append(post)
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
