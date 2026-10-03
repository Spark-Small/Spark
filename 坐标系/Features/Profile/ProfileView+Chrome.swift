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
        showEditProfile: Binding<Bool>,
        showSettingsFromTip: Binding<Bool>,
        youthBlockedMessage: Binding<String?>
    ) -> some View {
        sheet(isPresented: showEditProfile) {
            EditProfileSheet(user: Binding(
                get: { app.user },
                set: { updated in app.updateProfile(updated) }
            ))
            .platformHiddenTabBar()
        }
        .navigationDestination(isPresented: showSettingsFromTip) {
            ProfileSettingsView()
                .platformHiddenTabBar()
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
        .navigationDestination(for: CommunityLibraryDestination.self) { destination in
            CommunityLibraryRouter(destination: destination)
                .platformHiddenTabBar()
        }
        .circleBrowseStackChrome(
            buddies: buddies,
            messages: messages,
            memberName: app.user.name,
            blockedUserNames: app.blockedUserNames,
            onBrowseBuddies: { app.selectedTab = .buddies },
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
