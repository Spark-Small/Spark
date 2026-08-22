//
//  CommunityPostActionSheets.swift
//  坐标系
//

import SwiftUI
import UIKit

enum CommunityActionSheet: String, Identifiable {
    case likes
    case comments
    case repost
    case send
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
        if names.count < min(post?.likeCount ?? 0, 8) {
            for nickname in SampleData.circleBuddies.map(\.profile.nickname) {
                if nickname != app.user.name, !names.contains(nickname) {
                    names.append(nickname)
                }
                if names.count >= max(post?.likeCount ?? 0, 1) { break }
            }
        }
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
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
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
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("分享", systemImage: "square.and.arrow.up") {
                        showShare = true
                    }
                    Button(MessagesCopy.close) { dismiss() }
                }
            }
            .sheet(isPresented: $showShare) {
                CommunityShareSheet(postID: postID)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(item: $translateComment) { comment in
                CommunityCommentTranslateSheet(comment: comment)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .platformSheet(.form)
    }
}

// MARK: - Share / Forward

/// 分享与转发：搜索联系人网格 + 底部快捷操作（对齐主流社交分享 Sheet）。
struct CommunityShareSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var query = ""
    @State private var sentNames: Set<String> = []
    @State private var showStartChat = false
    @State private var showQuoteComposer = false
    @State private var quoteDraft = ""
    @State private var showRepostDetail = false
    @State private var didCopyLink = false

    private var isReposted: Bool { model.isReposted(postID) }

    private var recipients: [DiscoverBuddyItem] {
        let pooled = buddies.freeItems + buddies.paidItems
        let all = pooled.isEmpty
            ? SampleData.circleBuddies.map(DiscoverBuddyItem.free)
                + SampleData.paidCompanions.map(DiscoverBuddyItem.paid)
            : pooled
        // Sample data reuses nicknames across free/paid pools; uniqueKeysWithValues crashes on dups.
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

    private var avatarSide: CGFloat {
        (dynamicTypeSize.listAvatarSide * 2.1).rounded(.toNearestOrAwayFromZero)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: PlatformMetrics.railCardSpacing), count: 3)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
                    if !sentNames.isEmpty {
                        VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                            Text("最近已发送")
                                .font(.headline)
                            Text(sentNames.sorted().joined(separator: "、"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, PlatformMetrics.contentInset)
                    }

                    LazyVGrid(columns: gridColumns, spacing: PlatformMetrics.sectionHeaderSpacing) {
                        ForEach(recipients) { buddy in
                            recipientCell(buddy)
                        }
                    }
                }
                .padding(.top, PlatformMetrics.minContentGap)
                .padding(.bottom, PlatformMetrics.sectionSpacing)
            }
            .background(PlatformSurface.canvas)
            .safeAreaInset(edge: .top, spacing: 0) {
                shareSearchHeader
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                shareActionRail
            }
            .overlay {
                if recipients.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
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
        }
        .platformSheet(.browser)
    }

    private var shareSearchHeader: some View {
        HStack(spacing: PlatformMetrics.railCardSpacing) {
            HStack(spacing: PlatformMetrics.minContentGap) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemFill), in: Capsule())

            Button {
                showStartChat = true
            } label: {
                Image(systemName: "person.badge.plus")
                    .font(.body.weight(.semibold))
                    .frame(width: PlatformMetrics.navigationBarButtonSide, height: PlatformMetrics.navigationBarButtonSide)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("发起聊天")
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
        .padding(.vertical, PlatformMetrics.minContentGap)
        .background(.bar)
    }

    private var shareActionRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                shareAction(
                    title: isReposted ? "已转发" : "转发到社区",
                    systemImage: "arrow.2.squarepath",
                    tint: isReposted ? PlatformStatus.success : nil
                ) {
                    if isReposted {
                        showRepostDetail = true
                    } else {
                        model.createRepost(of: postID, quote: nil)
                        showRepostDetail = true
                    }
                }

                shareAction(title: "引用转发", systemImage: "text.quote") {
                    showQuoteComposer = true
                }

                shareAction(title: didCopyLink ? "已复制" : "复制链接", systemImage: didCopyLink ? "checkmark" : "link") {
                    copyLink()
                }

                shareAction(title: "分享到…", systemImage: "square.and.arrow.up") {
                    model.shareExternally(postID)
                }
            }
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
        }
        .background(.bar)
    }

    private func recipientCell(_ buddy: DiscoverBuddyItem) -> some View {
        let name = buddy.profile.nickname
        let sent = sentNames.contains(name)
        return Button {
            send(to: name)
        } label: {
            VStack(spacing: PlatformMetrics.minContentGap) {
                ZStack(alignment: .bottomTrailing) {
                    PlatformListAvatarView(name: name, side: avatarSide)
                    if sent {
                        Image(systemName: "checkmark.circle.fill")
                            .platformSymbolStyle(
                                .badge(primary: .white, secondary: Color.accentColor)
                            )
                            .background(Circle().fill(PlatformSurface.canvas).padding(-2))
                    }
                }
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sent ? "已发送给\(name)" : "发送给\(name)")
        .disabled(sent)
    }

    private func shareAction(
        title: String,
        systemImage: String,
        fill: Color? = nil,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: PlatformMetrics.minContentGap) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(fill == nil ? (tint ?? .primary) : .white)
                    .frame(width: PlatformMetrics.navigationBarButtonSide * 1.5, height: PlatformMetrics.navigationBarButtonSide * 1.5)
                    .background(
                        (fill ?? Color(.tertiarySystemFill)),
                        in: Circle()
                    )
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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

    private func send(to name: String) {
        guard !sentNames.contains(name) else { return }
        if app.shareCommunityPost(postID, to: name) != nil {
            sentNames.insert(name)
        }
    }

    private func copyLink() {
        let id = postID.uuidString
        UIPasteboard.general.string = "zuobiaoxi://community/\(id)"
        model.recordShare(postID)
        didCopyLink = true
    }
}

// MARK: - Repost (保留详情；主入口并入分享 Sheet)

struct CommunityRepostSheet: View {
    let postID: CommunityPost.ID

    var body: some View {
        CommunityShareSheet(postID: postID)
    }
}

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

/// 收藏确认 Sheet：已收藏状态行 + 创建收藏夹引导（对齐主流社交收藏面板）。
struct CommunityBookmarkSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateCollection = false
    @State private var newCollectionName = ""
    @State private var didBootstrap = false

    private var post: CommunityPost? { model.post(id: postID) }
    private var isBookmarked: Bool { model.isBookmarked(postID) }
    private var collectionName: String {
        model.bookmarkCollection(for: postID) ?? "私密"
    }

    private let presetCollections = ["全部收藏", "周末路线", "探店笔记", "稍后看"]

    var body: some View {
        VStack(spacing: 0) {
            confirmationRow
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.top, PlatformMetrics.sectionHeaderSpacing)
                .padding(.bottom, PlatformMetrics.sectionHeaderSpacing)

            Divider()

            guideSection
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.top, PlatformMetrics.sectionSpacing)
                .padding(.bottom, PlatformMetrics.sectionSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(PlatformSurface.canvas)
        .onAppear(perform: bootstrapBookmarkIfNeeded)
        .sheet(isPresented: $showCreateCollection) {
            createCollectionSheet
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .platformSheet(.confirm)
    }

    private var confirmationRow: some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            thumbnail
                .frame(width: PlatformConversationListRow.imageSide, height: PlatformConversationListRow.imageSide)
                .clipShape(RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(isBookmarked ? "已收藏" : "收藏")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Menu {
                    ForEach(presetCollections, id: \.self) { name in
                        Button(name) {
                            model.saveBookmark(postID, collection: name)
                        }
                    }
                    Button("创建收藏夹…") {
                        showCreateCollection = true
                    }
                    if isBookmarked {
                        Divider()
                        Button("取消收藏", role: .destructive) {
                            model.removeBookmark(postID)
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: PlatformMetrics.hairlineSpacing * 2) {
                        Text(collectionName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isBookmarked ? "已收藏，\(collectionName)" : "收藏")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let photo = post?.displayPhotos.first {
            CommunityRemotePhoto(ref: photo)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            ZStack {
                Color(.tertiarySystemFill)
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var guideSection: some View {
        VStack(spacing: PlatformMetrics.sectionHeaderSpacing) {
            HStack {
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: PlatformMetrics.navigationBarButtonSide * 0.85, height: PlatformMetrics.navigationBarButtonSide * 0.85)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭")
            }

            bookmarkHeroIcon

            VStack(spacing: PlatformMetrics.minContentGap) {
                Text("收藏你喜欢的帖子")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("把帖子收藏到你的专属收藏夹，或者与他人一起创建收藏夹。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, PlatformMetrics.minContentGap)

            Button("创建收藏夹") {
                showCreateCollection = true
            }
            .activityPrimaryCTA(controlSize: .large)
            .buttonSizing(.flexible)
            .padding(.top, PlatformMetrics.minContentGap)
        }
    }

    private var bookmarkHeroIcon: some View {
        ZStack {
            Image(systemName: "bookmark")
                .font(.system(.largeTitle, design: .default).weight(.light))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            // 轻装饰：系统色点缀，避免品牌彩虹风
            Capsule()
                .fill(Color.accentColor.opacity(0.55))
                .frame(width: 10, height: 3)
                .rotationEffect(.degrees(-28))
                .offset(x: -34, y: -18)
            Capsule()
                .fill(PlatformStatus.warning.opacity(0.7))
                .frame(width: 10, height: 3)
                .rotationEffect(.degrees(24))
                .offset(x: 34, y: -16)
            Capsule()
                .fill(PlatformStatus.success.opacity(0.65))
                .frame(width: 8, height: 3)
                .rotationEffect(.degrees(70))
                .offset(x: 30, y: 20)
            Capsule()
                .fill(Color.pink.opacity(0.55))
                .frame(width: 8, height: 3)
                .rotationEffect(.degrees(-60))
                .offset(x: -30, y: 18)
        }
        .frame(height: PlatformMetrics.detailRelatedThumb)
        .accessibilityHidden(true)
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
                    }
                    .fontWeight(.semibold)
                    .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .platformSheet(.form)
    }

    private func bootstrapBookmarkIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true
        if !isBookmarked {
            model.saveBookmark(postID, collection: "私密")
        }
    }
}

/// 本地评论译文（系统 Form；无网络翻译服务）
struct CommunityCommentTranslateSheet: View {
    let comment: CommunityComment
    @Environment(\.dismiss) private var dismiss

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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .platformSheet(.browser)
    }

    private var localTranslation: String {
        let trimmed = comment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "（空）" }
        return "〔译文〕\(trimmed)"
    }
}
