//
//  ProfileMyClubsView.swift
//  坐标系
//
//  「我的俱乐部」：与搭子俱乐部同款海报网格；Trailing 筛选 Menu + 创建。
//

import SwiftUI
import CoordinateModels

@MainActor
struct ProfileMyClubsView: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(TabNavigationState.self) private var navigation

    @State private var category: ProfileMyClubsCopy.Category = .all
    @State private var isComposingClub = false

    private var visibleClubs: [InterestCircle] {
        switch category {
        case .all:
            return buddies.membershipClubs
        case .hosted:
            return buddies.hostedClubs
        case .joined:
            let hostedIDs = Set(buddies.hostedClubs.map(\.id))
            return buddies.membershipClubs.filter { !hostedIDs.contains($0.id) }
        }
    }

    private var posterColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: PlatformMetrics.discoverCardSpacing),
            count: PlatformMetrics.personGridColumnCount
        )
    }

    var body: some View {
        Group {
            if visibleClubs.isEmpty {
                emptyContent
            } else {
                ScrollView {
                    LazyVGrid(columns: posterColumns, spacing: PlatformMetrics.discoverCardSpacing) {
                        ForEach(visibleClubs) { circle in
                            BuddyPosterShelfCard.circle(
                                circle,
                                memberCount: buddies.displayedMemberCount(
                                    for: circle,
                                    messages: messages,
                                    viewerName: app.user.name
                                )
                            ) {
                                navigation.openCircle(circle)
                            }
                        }
                    }
                    .discoverBrowseContentInset()
                    .discoverBrowsePageColumn()
                }
                .profileLibraryBrowseChrome()
            }
        }
        .navigationTitle(ProfileMyClubsCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ProfileLibraryCategoryMenu(
                    selection: $category,
                    options: Array(ProfileMyClubsCopy.Category.allCases),
                    accessibilityLabel: ProfileMyClubsCopy.pickerAccessibility,
                    accessibilityHint: ProfileMyClubsCopy.filterMenuHint,
                    title: \.segmentTitle,
                    systemImage: \.systemImage,
                    tag: { $0 },
                    labelStyle: .filterIcon(
                        systemImage: category.toolbarSystemImage,
                        accessibilityTitle: category.isFilterActive
                            ? ProfileMyClubsCopy.Toolbar.filterActive
                            : ProfileMyClubsCopy.Toolbar.filter
                    )
                )
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isComposingClub = true
                } label: {
                    Image(systemName: "plus")
                }
                .platformNavigationBarItemChrome()
                .accessibilityLabel(ProfileMyClubsCopy.createAccessibility)
                .accessibilityHint(ProfileMyClubsCopy.createAccessibilityHint)
            }
        }
        .sheet(isPresented: $isComposingClub) {
            CircleComposeSheet { circle in
                if let convo = messages.startCircleChat(
                    for: circle,
                    memberName: app.user.name
                ) {
                    buddies.attachJoinConversation(convo.id)
                }
                navigation.openCircle(circle)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    private var emptyContent: some View {
        ProfileLibraryEmptyView(
            title: category.emptyTitle,
            systemImage: category.emptySystemImage,
            description: category.emptyDescription
        ) {
            Button(ProfileMyClubsCopy.createAction) {
                isComposingClub = true
            }
            Button(ProfileMyClubsCopy.browseDiscover) {
                app.pendingBuddiesRoute = .clubDiscover
                app.selectedTab = .buddies
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileMyClubsView()
    }
    .environment(AppModel.preview)
    .environment(AppModel.preview.buddies)
    .environment(AppModel.preview.messages)
    .environment(TabNavigationState())
}
