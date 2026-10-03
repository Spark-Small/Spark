//
//  CommunityLibraryViews.swift
//  坐标系
//
//  广场内容库：收藏 / 赞过 / 我的分享 / 转发 / 公约。
//  入口：「我的」→「广场内容」Hub；根栈仍注册目的地便于深链。
//

import SwiftUI
import CoordinateModels

enum CommunityLibraryDestination: Hashable {
    case bookmarks
    case liked
    case myPosts
    case reposts
    case guidelines
}

struct CommunityLibraryRouter: View {
    let destination: CommunityLibraryDestination

    var body: some View {
        switch destination {
        case .bookmarks:
            CommunityBookmarksView()
        case .liked:
            CommunityLikedPostsView()
        case .myPosts:
            CommunityMyPostsView()
        case .reposts:
            CommunityMyRepostsView()
        case .guidelines:
            CommunityGuidelinesView()
        }
    }
}

// MARK: - Shared list

struct CommunityPostLibraryList: View {
    let title: String
    let emptyTitle: String
    let emptySystemImage: String
    let emptyDescription: String
    let posts: [CommunityPost]
    var footnote: ((CommunityPost) -> String?)? = nil

    var body: some View {
        List {
            if posts.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptySystemImage,
                    description: Text(emptyDescription)
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(posts) { post in
                    NavigationLink(value: post) {
                        PlatformListTextColumn(
                            primary: post.messageText,
                            secondary: librarySecondary(for: post),
                            footnote: footnote?(post),
                            primaryLineLimit: 2,
                            secondaryLineLimit: 1,
                            footnoteLineLimit: 1
                        )
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func librarySecondary(for post: CommunityPost) -> String {
        let time = Formatters.conversationListTime(from: post.postedAt)
        if post.author.isEmpty {
            return time
        }
        return "\(post.author) · \(time)"
    }
}

// MARK: - Pages

struct CommunityBookmarksView: View {
    @Environment(CommunityModel.self) private var model

    var body: some View {
        CommunityPostLibraryList(
            title: CommunityLibraryCopy.bookmarksTitle,
            emptyTitle: CommunityLibraryCopy.bookmarksEmpty,
            emptySystemImage: "bookmark",
            emptyDescription: CommunityLibraryCopy.bookmarksEmptyHint,
            posts: model.bookmarkedPosts,
            footnote: { model.bookmarkCollection(for: $0.id) }
        )
    }
}

struct CommunityLikedPostsView: View {
    @Environment(CommunityModel.self) private var model

    var body: some View {
        CommunityPostLibraryList(
            title: CommunityLibraryCopy.likedTitle,
            emptyTitle: CommunityLibraryCopy.likedEmpty,
            emptySystemImage: "heart",
            emptyDescription: CommunityLibraryCopy.likedEmptyHint,
            posts: model.likedPosts
        )
    }
}

struct CommunityMyPostsView: View {
    @Environment(CommunityModel.self) private var model

    var body: some View {
        CommunityPostLibraryList(
            title: CommunityLibraryCopy.myPostsTitle,
            emptyTitle: CommunityLibraryCopy.myPostsEmpty,
            emptySystemImage: "square.and.pencil",
            emptyDescription: CommunityLibraryCopy.myPostsEmptyHint,
            posts: model.myPosts
        )
    }
}

struct CommunityMyRepostsView: View {
    @Environment(CommunityModel.self) private var model

    var body: some View {
        CommunityPostLibraryList(
            title: CommunityLibraryCopy.repostsTitle,
            emptyTitle: CommunityLibraryCopy.repostsEmpty,
            emptySystemImage: "arrow.2.squarepath",
            emptyDescription: CommunityLibraryCopy.repostsEmptyHint,
            posts: model.myReposts
        )
    }
}

struct CommunityGuidelinesView: View {
    var body: some View {
        List {
            Section {
                Text(CommunityLibraryCopy.guidelinesIntro)
                    .font(PlatformListTypography.body)
                    .foregroundStyle(.secondary)
            }

            Section(CommunityLibraryCopy.guidelinesDoHeader) {
                Label(CommunityLibraryCopy.guidelineDoExperience, systemImage: "checkmark.circle")
                    .platformContentSymbolStyle()
                Label(CommunityLibraryCopy.guidelineDoRespect, systemImage: "hand.raised")
                    .platformContentSymbolStyle()
                Label(CommunityLibraryCopy.guidelineDoAttribution, systemImage: "person.crop.rectangle")
                    .platformContentSymbolStyle()
            }

            Section(CommunityLibraryCopy.guidelinesDontHeader) {
                Label(CommunityLibraryCopy.guidelineDontHarassment, systemImage: "xmark.circle")
                    .platformContentSymbolStyle()
                Label(CommunityLibraryCopy.guidelineDontSpam, systemImage: "megaphone")
                    .platformContentSymbolStyle()
                Label(CommunityLibraryCopy.guidelineDontIllegal, systemImage: "exclamationmark.triangle")
                    .platformContentSymbolStyle()
            }

            Section {
                Text(CommunityLibraryCopy.guidelinesFooter)
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(CommunityLibraryCopy.guidelinesTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
