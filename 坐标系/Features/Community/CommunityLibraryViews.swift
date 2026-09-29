//
//  CommunityLibraryViews.swift
//  坐标系
//
//  社区「更多」入口与「我的内容库」共用：收藏 / 赞过 / 我的分享 / 转发 / 公约。
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
        // 分享详情目的地由外层 NavigationStack 注册
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
            title: "收藏的分享",
            emptyTitle: "还没有收藏分享",
            emptySystemImage: "bookmark",
            emptyDescription: "在社区分享里点收藏，种草与复盘会出现在这里；也可在「我的内容库」统一查看。",
            posts: model.bookmarkedPosts,
            footnote: { model.bookmarkCollection(for: $0.id) }
        )
    }
}

struct CommunityLikedPostsView: View {
    @Environment(CommunityModel.self) private var model

    var body: some View {
        CommunityPostLibraryList(
            title: "赞过的",
            emptyTitle: "还没有赞过分享",
            emptySystemImage: "heart",
            emptyDescription: "点赞过的分享会出现在这里；也可在「我的内容库」统一查看。",
            posts: model.likedPosts
        )
    }
}

struct CommunityMyPostsView: View {
    @Environment(CommunityModel.self) private var model

    var body: some View {
        CommunityPostLibraryList(
            title: "我的分享",
            emptyTitle: "还没有发布分享",
            emptySystemImage: "square.and.pencil",
            emptyDescription: "发布的活动图文会出现在这里；完整创作凭证见「我的内容库」。",
            posts: model.myPosts
        )
    }
}

struct CommunityMyRepostsView: View {
    @Environment(CommunityModel.self) private var model

    var body: some View {
        CommunityPostLibraryList(
            title: "我的转发",
            emptyTitle: "还没有转发",
            emptySystemImage: "arrow.2.squarepath",
            emptyDescription: "转发到社区的分享会出现在这里；也可在「我的内容库」统一查看。",
            posts: model.myReposts
        )
    }
}

struct CommunityGuidelinesView: View {
    var body: some View {
        List {
            Section {
                Text("坐标系社区用于分享活动种草、路线与复盘。一起把真实体验留给后来的人。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Section("请这样发") {
                Label("分享真实到场体验，配上清楚的地点与时间", systemImage: "checkmark.circle")
                    .platformContentSymbolStyle()
                Label("尊重他人，讨论聚焦活动本身", systemImage: "hand.raised")
                    .platformContentSymbolStyle()
                Label("转载请注明来源，不冒用他人照片", systemImage: "person.crop.rectangle")
                    .platformContentSymbolStyle()
            }

            Section("请避免") {
                Label("骚扰、人身攻击与恶意举报", systemImage: "xmark.circle")
                    .platformContentSymbolStyle()
                Label("广告灌水、虚假活动信息", systemImage: "megaphone")
                    .platformContentSymbolStyle()
                Label("色情低俗、违法违规内容", systemImage: "exclamationmark.triangle")
                    .platformContentSymbolStyle()
            }

            Section {
                Text("违规内容可在分享详情中举报。我们会尽快处理；恶意举报也可能影响账号权限。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("社区公约")
        .navigationBarTitleDisplayMode(.inline)
    }
}
