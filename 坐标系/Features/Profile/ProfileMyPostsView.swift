//
//  ProfileMyPostsView.swift
//  坐标系
//
//  「我的发帖」：有内容走 List；空态独立铺页；顶栏草稿箱 + 发帖。
//

import SwiftUI
import CoordinateModels

@MainActor
struct ProfileMyPostsView: View {
    var initialCategory: ProfileMyPostsCopy.Category = .all

    @Environment(CommunityModel.self) private var community
    @Environment(AppModel.self) private var app
    @State private var category: ProfileMyPostsCopy.Category
    @State private var searchText = ""

    init(initialCategory: ProfileMyPostsCopy.Category = .all) {
        self.initialCategory = initialCategory
        _category = State(initialValue: initialCategory)
    }

    private var visiblePosts: [CommunityPost] {
        let base: [CommunityPost]
        switch category {
        case .all:
            base = community.myPosts + community.myReposts
        case .original:
            base = community.myPosts
        case .reposts:
            base = community.myReposts
        }
        let sorted = base.sorted { $0.postedAt > $1.postedAt }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter { post in
            post.messageText.localizedCaseInsensitiveContains(query)
                || post.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || (post.relatedActivityTitle?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var draftCount: Int {
        community.postDrafts.count
    }

    var body: some View {
        @Bindable var community = community

        Group {
            if visiblePosts.isEmpty {
                emptyContent
            } else {
                List {
                    ForEach(visiblePosts) { post in
                        NavigationLink(value: post) {
                            ProfileMyPostsRow(post: post)
                        }
                    }
                }
                .profileSecondaryListChrome()
            }
        }
        .navigationTitle(ProfileMyPostsCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: ProfileMyPostsCopy.searchPrompt
        )
        .toolbar {
            // 与「我的」根铃铛/设置同族：分组 + ToolbarSpacer，避免两枚图标糊成一团。
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    ProfileMyPostsDraftsView()
                        .toolbarVisibility(.hidden, for: .tabBar)
                } label: {
                    Image(
                        systemName: draftCount == 0
                            ? ProfileMyPostsCopy.Drafts.idleSystemImage
                            : ProfileMyPostsCopy.Drafts.filledSystemImage
                    )
                }
                .platformNavigationBarItemChrome()
                .accessibilityLabel(ProfileMyPostsCopy.Drafts.toolbarAccessibility)
                .accessibilityHint(ProfileMyPostsCopy.Drafts.toolbarHint)
                .accessibilityValue(
                    ProfileMyPostsCopy.Drafts.toolbarAccessibilityValue(count: draftCount)
                )
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    community.beginCompose()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .platformNavigationBarItemChrome()
                .accessibilityLabel(ProfileMyPostsCopy.composeAccessibility)
                .accessibilityHint(ProfileMyPostsCopy.composeAccessibilityHint)
            }
        }
        .onAppear {
            community.reloadPostDrafts()
        }
        .sheet(
            isPresented: $community.presentation.isComposing,
            onDismiss: { community.presentation.endCompose() }
        ) {
            CommunityComposeSheet()
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    @ViewBuilder
    private var emptyContent: some View {
        if isSearching {
            ContentUnavailableView.search(text: searchText)
                .platformContentUnavailablePageChrome()
        } else {
            ProfileLibraryEmptyView(
                title: category.emptyTitle,
                systemImage: category.systemImage,
                description: category.emptyDescription
            ) {
                Button(ProfileMyPostsCopy.composeAction) {
                    community.beginCompose()
                }
                Button(ProfileMyPostsCopy.browseCommunity) {
                    app.selectedTab = .community
                }
            }
        }
    }
}

// MARK: - Row

private struct ProfileMyPostsRow: View {
    let post: CommunityPost

    var body: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            if let cover = post.coverPhoto {
                CommunityRemotePhoto(ref: cover)
                    .frame(
                        width: PlatformConversationListRow.imageSide,
                        height: PlatformConversationListRow.imageSide
                    )
                    .clipShape(RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous))
                    .accessibilityHidden(true)
            }

            PlatformListTextColumn(
                primary: post.messageText,
                secondary: Formatters.conversationListTime(from: post.postedAt),
                footnote: footnote,
                primaryLineLimit: 2,
                secondaryLineLimit: 1,
                footnoteLineLimit: 1
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var footnote: String? {
        var parts: [String] = [
            ProfileMyPostsCopy.engagementLine(likes: post.likeCount, comments: post.commentCount)
        ]
        if post.isRepost {
            parts.append(ProfileMyPostsCopy.repostFootnote)
        }
        if let activity = post.relatedActivityTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !activity.isEmpty {
            parts.append(activity)
        }
        return parts.joined(separator: " · ")
    }
}
