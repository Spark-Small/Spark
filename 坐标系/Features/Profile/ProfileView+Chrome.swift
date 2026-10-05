//
//  ProfileView+Chrome.swift
//  坐标系
//
//  「我的」根：Sheet / Alert / 栈目的地与深链辅助。
//

import SwiftUI
import CoordinateModels

@MainActor
func profileOpenClubConversation(
    _ conversationID: UUID,
    navigation: TabNavigationState,
    messages: MessagesModel,
    buddies: BuddiesModel,
    app: AppModel
) {
    guard let conversation = messages.conversations.first(where: { $0.id == conversationID }),
          conversation.kind == .circle,
          let circleID = conversation.relatedCircleID,
          let circle = buddies.circle(id: circleID)
    else {
        app.openMessages(conversationID: conversationID)
        return
    }
    guard let route = app.prepareClubGroupChatRoute(for: circle) else { return }
    navigation.openClubGroupChat(for: circle, route: route)
}

extension View {
    func profileRootPresentations(
        app: AppModel,
        showLikesReceivedInfo: Binding<Bool>,
        likesReceivedCount: Int,
        youthBlockedMessage: Binding<String?>
    ) -> some View {
        alert(
            ProfileSocialCopy.likesTitle(name: app.user.name, count: likesReceivedCount),
            isPresented: showLikesReceivedInfo
        ) {
            Button(ProfileSocialCopy.likesDismiss, role: .cancel) {}
        } message: {
            Text(ProfileSocialCopy.likesDescription)
        }
        .alert("青少年模式", isPresented: youthBlockedMessage.isOptionalPresented) {
            Button("好的", role: .cancel) { youthBlockedMessage.wrappedValue = nil }
        } message: {
            Text(youthBlockedMessage.wrappedValue ?? "")
        }
    }

    func profileRootDestinations(
        navigation: TabNavigationState,
        buddies: BuddiesModel,
        messages: MessagesModel,
        app: AppModel,
        activityZoomNamespace: Namespace.ID
    ) -> some View {
        navigationDestination(for: CommunityPost.self) { post in
            CommunityPostDetailView(postID: post.id)
                .platformHiddenTabBar()
        }
        .circleBrowseStackChrome(
            buddies: buddies,
            messages: messages,
            memberName: app.user.name,
            blockedUserNames: app.blockedUserNames,
            onBrowseBuddies: {
                app.pendingBuddiesRoute = .socialBrowse
                app.selectedTab = .buddies
            },
            openCircle: { navigation.openCircle($0) },
            openConversation: { conversationID in
                profileOpenClubConversation(
                    conversationID,
                    navigation: navigation,
                    messages: messages,
                    buddies: buddies,
                    app: app
                )
            }
        )
        // 邀约/预约详情「搭子资料」走 BuddyZoomRoute，须在「我的」栈注册。
        .buddyZoomNavigationDestination(namespace: activityZoomNamespace)
        .activityPeerChatNavigationDestination()
        .activityZoomNavigationDestination(namespace: activityZoomNamespace)
        .navigationDestination(for: ProfileRoute.self) { route in
            ProfileRouteDestination(route: route)
                .platformHiddenTabBar()
        }
    }
}

fileprivate extension Binding where Value == String? {
    var isOptionalPresented: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { isPresented in
                if !isPresented { wrappedValue = nil }
            }
        )
    }
}
