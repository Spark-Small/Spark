//
//  CommunityPostActionSheets.swift
//  坐标系
//

import SwiftUI
import UIKit
import CoordinateModels

enum CommunityActionSheet: String, Identifiable {
    case likes
    case comments
    case share
    case bookmark

    var id: String { rawValue }
}

// MARK: - Likes

struct CommunityLikesSheet: View {
    let postID: CommunityPost.ID
    @Environment(CommunityModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @State private var selectedBuddy: DiscoverBuddyItem?

    private var post: CommunityPost? { model.post(id: postID) }
    private var isLiked: Bool { model.isLiked(postID) }

    private var likers: [String] {
        var names = model.likerNames(for: postID)
        if post != nil {
            for author in CommunityCommentsStore.comments(for: postID).map(\.author) where !names.contains(author) {
                names.append(author)
            }
        }
        // 仅展示真实赞 / 评论作者，不拿 SampleData 补人数。
        return Array(names.prefix(max(post?.likeCount ?? names.count, names.count)))
    }

    var body: some View {
        MessagesFormSheet(title: "赞") {
            List {
                Section {
                    Button {
                        model.toggleLike(postID)
                    } label: {
                        Label(
                            isLiked ? "取消赞" : "赞",
                            systemImage: isLiked ? "heart.fill" : "heart"
                        )
                        .foregroundStyle(isLiked ? PlatformStatus.danger : Color.primary)
                    }
                }

                Section("赞过的人") {
                    if likers.isEmpty {
                        Text("还没有人赞过")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(likers, id: \.self) { name in
                            Button {
                                selectedBuddy = buddies.item(for: name)
                            } label: {
                                Label {
                                    HStack {
                                        Text(name)
                                        Spacer(minLength: 0)
                                        if name == app.user.name {
                                            Text("你")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                } icon: {
                                    PlatformSystemAvatar(side: PlatformConversationListRow.imageSide)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedBuddy) { item in
                NavigationStack {
                    BuddyDetailRouteView(item: item)
                        .platformSheetConfirmationToolbar()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
                .platformSheet(.browser)
            }
        }
    }
}

// MARK: - Comments

struct CommunityCommentsSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @State private var translateComment: CommunityComment?

    private var post: CommunityPost? { model.post(id: postID) }

    var body: some View {
        NavigationStack {
            Group {
                if post != nil {
                    PlatformReviewsCommentsHost(
                        target: .community(postID),
                        currentUserName: model.currentUserName,
                        layout: .sheetList,
                        contentOwnerName: post?.author,
                        emptyTitle: "抢先评论",
                        emptyHint: "我来说两句…",
                        placeholder: "我来说两句...",
                        showsTranslate: true,
                        onTranslate: { translateComment = $0.asCommunityComment },
                        onChanged: { model.syncComments(for: postID) }
                    )
                    .id(model.commentRevision)
                } else {
                    ContentUnavailableView("动态不存在", systemImage: "bubble.right")
                }
            }
            .navigationTitle(post.map { "评论 \($0.commentCount)" } ?? "评论")
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetCancellationToolbar(MessagesCopy.close)
            .sheet(item: $translateComment) { comment in
                CommunityCommentTranslateSheet(comment: comment)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .platformSheet(.form)
    }
}

// MARK: - Share / Forward

struct CommunityShareSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var sentNames: Set<String> = []
    @State private var showStartChat = false
    @State private var showQuoteComposer = false
    @State private var quoteDraft = ""
    @State private var showRepostDetail = false
    @State private var didCopyLink = false
    @State private var showSystemShare = false

    private var isReposted: Bool { model.isReposted(postID) }

    private var deepLink: String {
        "zuobiaoxi://community/\(postID.uuidString)"
    }

    private var sharePayload: String {
        model.post(id: postID)?.shareText ?? deepLink
    }

    private var recipients: [DiscoverBuddyItem] {
        CommunityShareRecipients.filtered(from: buddies, query: query)
    }

    var body: some View {
        MessagesFormSheet(title: "分享") {
            List {
                Section {
                    Button {
                        showStartChat = true
                    } label: {
                        Label("发起聊天", systemImage: "person.badge.plus")
                    }
                }

                Section("发送给") {
                    if recipients.isEmpty {
                        Text(query.isEmpty ? "暂无联系人" : "无匹配结果")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recipients) { buddy in
                            recipientRow(buddy)
                        }
                    }
                }

                Section("更多") {
                    Button {
                        if !isReposted {
                            model.createRepost(of: postID, quote: nil)
                        }
                        showRepostDetail = true
                    } label: {
                        Label(
                            isReposted ? "查看转发" : "转发到社区",
                            systemImage: "arrow.2.squarepath"
                        )
                    }

                    Button {
                        showQuoteComposer = true
                    } label: {
                        Label("引用转发", systemImage: "text.quote")
                    }

                    Button {
                        UIPasteboard.general.string = deepLink
                        model.recordShare(postID)
                        didCopyLink = true
                    } label: {
                        Label(
                            didCopyLink ? "已复制链接" : "复制链接",
                            systemImage: didCopyLink ? "checkmark" : "link"
                        )
                    }

                    Button {
                        model.recordShare(postID)
                        showSystemShare = true
                    } label: {
                        Label("分享到…", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .searchable(text: $query, prompt: "搜索联系人")
            .sheet(isPresented: $showStartChat) {
                StartChatSheet { conversationID in
                    showStartChat = false
                    dismiss()
                    app.openMessages(conversationID: conversationID)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showQuoteComposer) {
                quoteComposer
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showRepostDetail) {
                CommunityRepostDetailSheet(originalID: postID)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showSystemShare) {
                PlatformShareSheet(items: [sharePayload])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }

    private func recipientRow(_ buddy: DiscoverBuddyItem) -> some View {
        let name = buddy.profile.nickname
        let sent = sentNames.contains(name)
        return Button {
            guard !sent, app.shareCommunityPost(postID, to: name) != nil else { return }
            sentNames.insert(name)
        } label: {
            Label {
                HStack {
                    Text(name)
                    Spacer(minLength: 0)
                    if sent {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)
                    }
                }
            } icon: {
                PlatformListAvatarView(
                    name: name,
                    side: PlatformConversationListRow.imageSide
                )
            }
        }
        .disabled(sent)
        .accessibilityLabel(sent ? "已发送给\(name)" : "发送给\(name)")
    }

    private var quoteComposer: some View {
        NavigationStack {
            Form {
                TextField("写下你的想法…", text: $quoteDraft, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("引用转发")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showQuoteComposer = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        model.createRepost(of: postID, quote: quoteDraft)
                        quoteDraft = ""
                        showQuoteComposer = false
                        showRepostDetail = true
                    }
                    .fontWeight(.semibold)
                    .disabled(quoteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .platformSheet(.form)
    }
}

@MainActor
private enum CommunityShareRecipients {
    static func filtered(from buddies: BuddiesModel, query: String) -> [DiscoverBuddyItem] {
        let pooled = buddies.freeItems + buddies.paidItems
        let all = pooled.isEmpty
            ? SampleData.circleBuddies.map(DiscoverBuddyItem.free)
                + SampleData.paidCompanions.map(DiscoverBuddyItem.paid)
            : pooled

        var seenIDs = Set<UUID>()
        var seenNicks = Set<String>()
        var unique: [DiscoverBuddyItem] = []
        for item in all {
            let nick = item.profile.nickname.lowercased()
            guard seenIDs.insert(item.id).inserted else { continue }
            guard seenNicks.insert(nick).inserted else { continue }
            unique.append(item)
        }
        unique.sort {
            $0.profile.nickname.localizedStandardCompare($1.profile.nickname) == .orderedAscending
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return unique }
        return unique.filter {
            $0.profile.nickname.localizedCaseInsensitiveContains(trimmed)
                || $0.profile.tags.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }
}

// MARK: - Repost detail

struct CommunityRepostDetailSheet: View {
    let originalID: CommunityPost.ID
    @Environment(CommunityModel.self) private var model

    private var original: CommunityPost? { model.post(id: originalID) }
    private var myReposts: [CommunityPost] {
        model.posts.filter { $0.repostedFromID == originalID && $0.author == model.currentUserName }
    }

    var body: some View {
        MessagesFormSheet(title: "转发详情") {
            List {
                if let original {
                    Section("原文") {
                        Text(original.messageText).font(.body)
                        Text(Formatters.conversationListTime(from: original.postedAt))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Section("我的转发") {
                    if myReposts.isEmpty {
                        Text("暂无转发记录").foregroundStyle(.secondary)
                    } else {
                        ForEach(myReposts) { post in
                            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                                Text(post.messageText).font(.subheadline)
                                Text(Formatters.conversationListTime(from: post.postedAt))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Bookmark

struct CommunityBookmarkSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateCollection = false
    @State private var newCollectionName = ""

    private let presetCollections = ["私密", "全部收藏", "周末路线", "探店笔记", "稍后看"]

    var body: some View {
        MessagesFormSheet(title: "收藏", dismissAction: .cancel) {
            List {
                Section {
                    ForEach(presetCollections, id: \.self) { name in
                        Button {
                            model.saveBookmark(postID, collection: name)
                            dismiss()
                        } label: {
                            Text(name)
                                .foregroundStyle(.primary)
                        }
                    }

                    Button {
                        showCreateCollection = true
                    } label: {
                        Label("创建收藏夹…", systemImage: "folder.badge.plus")
                    }
                } header: {
                    Text("收藏到")
                }
            }
            .sheet(isPresented: $showCreateCollection) {
                createCollectionSheet
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }

    private var createCollectionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("收藏夹名称", text: $newCollectionName)
                        .textInputAutocapitalization(.never)
                } footer: {
                    Text("创建后，这条分享会放进该收藏夹。")
                }
            }
            .navigationTitle("创建收藏夹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        newCollectionName = ""
                        showCreateCollection = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        model.saveBookmark(postID, collection: name)
                        newCollectionName = ""
                        showCreateCollection = false
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .platformSheet(.form)
    }
}

// MARK: - Translate

struct CommunityCommentTranslateSheet: View {
    let comment: CommunityComment

    var body: some View {
        NavigationStack {
            Form {
                Section("原文") {
                    Text(comment.text)
                        .font(.body)
                        .textSelection(.enabled)
                }
                Section {
                    Text(localTranslation)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                } header: {
                    Text("译文")
                } footer: {
                    Text("本地演示译文，仅便于阅读；正式版可接入系统翻译。")
                }
            }
            .navigationTitle("查看翻译")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .platformSheetConfirmationToolbar()
        }
        .platformSheet(.browser)
    }

    private var localTranslation: String {
        let trimmed = comment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "（空）" }
        return "〔译文〕\(trimmed)"
    }
}
