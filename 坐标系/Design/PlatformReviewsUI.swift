//
//  PlatformReviewsUI.swift
//  坐标系
//
//  统一评价 / 评论 UI：筛选、星级卡、线程回复与输入框。
//

import SwiftUI

// MARK: - Header / Filter

struct PlatformReviewsHeader: View {
    let count: Int
    var title: (Int) -> String = BuddyDetailCopy.reviewsTitleCount

    var body: some View {
        Text(title(count))
            .textCase(nil)
            .accessibilityAddTraits(.isHeader)
    }
}

struct PlatformReviewFilterBar: View {
    @Binding var filter: PlatformReviewFilter
    let stats: PlatformReviewStats

    var body: some View {
        Picker("筛选", selection: $filter) {
            Text("全部 \(stats.total)").tag(PlatformReviewFilter.all)
            Text("好评 \(stats.positive)").tag(PlatformReviewFilter.positive)
            Text("有图 \(stats.withPhotos)").tag(PlatformReviewFilter.withPhotos)
            Text(PlatformReviewFilter.latest.rawValue).tag(PlatformReviewFilter.latest)
        }
        .pickerStyle(.menu)
        .accessibilityLabel("评价筛选")
    }
}

// MARK: - Reactions

struct PlatformCommentReactionButtons: View {
    var isLiked: Bool
    var isDisliked: Bool
    var font: Font = PlatformListTypography.footnote
    var multicolorLike = true
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            reactionButton(
                title: "不喜欢",
                filledSystemName: "hand.thumbsdown.fill",
                outlineSystemName: "hand.thumbsdown",
                isActive: isDisliked,
                activeColor: .secondary,
                multicolor: false,
                action: onDislike
            )
            reactionButton(
                title: "赞",
                filledSystemName: "heart.fill",
                outlineSystemName: "heart",
                isActive: isLiked,
                activeColor: PlatformStatus.danger,
                multicolor: multicolorLike,
                action: onLike
            )
        }
        .font(font)
    }

    @ViewBuilder
    private func reactionButton(
        title: String,
        filledSystemName: String,
        outlineSystemName: String,
        isActive: Bool,
        activeColor: Color,
        multicolor: Bool,
        action: (() -> Void)?
    ) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: isActive ? filledSystemName : outlineSystemName)
                .symbolRenderingMode(multicolor ? .multicolor : .monochrome)
                .foregroundStyle(isActive ? activeColor : .secondary)
        }
        .buttonStyle(.borderless)
        .controlSize(.regular)
        .disabled(action == nil)
        .accessibilityLabel(isActive ? "取消\(title)" : title)
    }
}

// MARK: - Rated card

struct PlatformReviewRatedCard: View {
    let review: PlatformReview
    var usesFormRowStyle = false
    var showsLike = true
    var isLiked = false
    var isDisliked = false
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil
    var onReply: (() -> Void)? = nil

    private var photoSide: CGFloat { 88 }

    var body: some View {
        if usesFormRowStyle {
            formRowBody
        } else {
            cardRowBody
        }
    }

    private var formRowBody: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(review.author)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)

                if let rating = review.rating {
                    starRow(rating)
                }

                Spacer(minLength: 0)

                Text(Formatters.reviewPostedTime(from: review.postedAt))
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            if let serviceLine = review.serviceLine {
                Text(serviceLine)
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(review.text)
                .font(PlatformListTypography.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if review.hasPhotos {
                photoGrid
            }

            formActionRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var cardRowBody: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
                PlatformListAvatarView(name: review.author, side: 36)

                VStack(alignment: .leading, spacing: metadataSpacing) {
                    Text(review.author)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let rating = review.rating {
                        HStack(spacing: PlatformMetrics.hairlineSpacing) {
                            starRow(rating)
                            if let serviceLine = review.serviceLine {
                                Text("|")
                                    .font(.caption2)
                                    .foregroundStyle(.quaternary)
                                Text(serviceLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } else if let serviceLine = review.serviceLine {
                        Text(serviceLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Text(review.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if review.hasPhotos {
                photoGrid
            }

            cardActionRow
        }
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .accessibilityElement(children: .combine)
    }

    private var formActionRow: some View {
        HStack {
            if let onReply {
                Button("回复", action: onReply)
                    .font(PlatformListTypography.footnote)
                    .buttonStyle(.borderless)
            }
            Spacer(minLength: 0)
            if showsLike {
                PlatformCommentReactionButtons(
                    isLiked: review.isLiked,
                    isDisliked: review.isDisliked,
                    font: PlatformListTypography.footnote,
                    multicolorLike: false,
                    onLike: onLike,
                    onDislike: onDislike
                )
            }
        }
        .foregroundStyle(.secondary)
    }

    private var cardActionRow: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.minContentGap) {
            Text(Formatters.reviewPostedTime(from: review.postedAt))
                .font(.caption)
                .foregroundStyle(.tertiary)
            if let onReply {
                Button("回复", action: onReply)
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            if showsLike {
                PlatformCommentReactionButtons(
                    isLiked: review.isLiked,
                    isDisliked: review.isDisliked,
                    font: .caption,
                    onLike: onLike,
                    onDislike: onDislike
                )
            }
        }
    }

    private var rowSpacing: CGFloat {
        usesFormRowStyle
            ? PlatformConversationListRow.textToSecondarySpacing
            : PlatformMetrics.cardInfoSpacing
    }

    private var metadataSpacing: CGFloat {
        usesFormRowStyle
            ? PlatformConversationListRow.textToSecondarySpacing
            : PlatformMetrics.hairlineSpacing
    }

    private func starRow(_ rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityLabel("\(rating) 星")
    }

    private var photoGrid: some View {
        HStack(spacing: PlatformMetrics.hairlineSpacing) {
            ForEach(Array(review.photoRefs.prefix(3).enumerated()), id: \.offset) { _, ref in
                CommunityRemotePhoto(ref: ref.communityPhotoRef)
                    .frame(width: photoSide, height: photoSide)
                    .clipShape(RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous))
            }
        }
        .accessibilityLabel("评价配图 \(review.photoRefs.count) 张")
    }
}

// MARK: - Unified host

/// 统一评论宿主：系统 List / Form 样式，楼中楼与回复。
struct PlatformReviewsCommentsHost: View {
    enum Layout {
        case formRows
        case sheetList
        case embedded
    }

    enum ComposerPlacement {
        case inline
        case external
    }

    let target: PlatformReviewTarget
    let currentUserName: String
    var layout: Layout
    var composerPlacement: ComposerPlacement = .inline
    var externalDraft: Binding<String>? = nil
    var externalReplyTarget: Binding<PlatformReview?>? = nil
    var contentOwnerName: String? = nil
    var ownerBadgeTitle = "作者"
    var emptyTitle: String = ActivityDetailCopy.commentsEmpty
    var emptyHint: String = ActivityDetailCopy.commentsEmptyHint
    var placeholder: String = ActivityDetailCopy.commentsPlaceholder
    var showsTranslate = false
    var companionFilter: Binding<PlatformReviewFilter>? = nil
    var companionStats: PlatformReviewStats? = nil
    var onTranslate: ((PlatformReview) -> Void)? = nil
    var onChanged: () -> Void = {}

    @State private var internalDraft = ""
    @State private var internalReplyTarget: PlatformReview?
    @State private var reviews: [PlatformReview] = []
    @State private var expandedThreadIDs: Set<UUID> = []
    @State private var blockedWord: String?
    @FocusState private var focused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var draftBinding: Binding<String> {
        externalDraft ?? $internalDraft
    }

    private var replyTargetBinding: Binding<PlatformReview?> {
        externalReplyTarget ?? $internalReplyTarget
    }

    private var draft: String {
        get { draftBinding.wrappedValue }
        nonmutating set { draftBinding.wrappedValue = newValue }
    }

    private var replyTarget: PlatformReview? {
        get { replyTargetBinding.wrappedValue }
        nonmutating set { replyTargetBinding.wrappedValue = newValue }
    }

    private var displayedRoots: [PlatformReview] {
        if let companionFilter {
            return PlatformReviewCatalog.filtered(
                reviews,
                filter: companionFilter.wrappedValue
            )
        }
        return PlatformReviewCatalog.sortedRoots(reviews)
    }

    private var showsInlineComposer: Bool {
        composerPlacement == .inline && layout == .formRows
    }

    private var usesListStyling: Bool {
        switch layout {
        case .formRows, .sheetList: return true
        case .embedded: return false
        }
    }

    private var commentRowStyle: CommunityCommentRowStyle {
        switch layout {
        case .formRows:
            return .form
        case .sheetList, .embedded:
            return .thread
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            switch layout {
            case .formRows:
                formAccessoryRows
                commentListContent
                if showsInlineComposer {
                    inlineComposerRow
                }
            case .sheetList:
                List {
                    formAccessoryRows
                    commentListContent
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.visible)
                .contentMargins(.top, 0, for: .scrollContent)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomComposer
                }
            case .embedded:
                commentListContent
                if showsInlineComposer {
                    inlineComposerRow
                }
            }
        }
        .onAppear(perform: reload)
        .alert("评论需要修改", isPresented: Binding(
            get: { blockedWord != nil },
            set: { if !$0 { blockedWord = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(blockedWord ?? "")
        }
    }

    @ViewBuilder
    private var formAccessoryRows: some View {
        if let companionFilter, let companionStats {
            PlatformReviewFilterBar(filter: companionFilter, stats: companionStats)
                .modifier(FormAccessoryRowModifier())
        }
    }

    @ViewBuilder
    private var commentListContent: some View {
        if displayedRoots.isEmpty {
            ContentUnavailableView(
                emptyTitle,
                systemImage: "bubble.right",
                description: Text(emptyHint)
            )
            .modifier(OptionalListRowBackgroundModifier(enabled: usesListStyling))
        } else {
            ForEach(displayedRoots) { root in
                threadBlock(root)
            }
        }
    }

    @ViewBuilder
    private func threadBlock(_ root: PlatformReview) -> some View {
        let replies = reviews.filter { $0.parentID == root.id }
        let isExpanded = expandedThreadIDs.contains(root.id)

        VStack(alignment: .leading) {
            reviewContent(root, isReply: false)

            if !replies.isEmpty {
                if isExpanded {
                    ForEach(replies) { reply in
                        reviewContent(reply, isReply: true)
                    }
                    threadToggleButton(title: "收起回复") {
                        expandedThreadIDs.remove(root.id)
                    }
                } else {
                    threadToggleButton(
                        title: replies.count == 1 ? "展开 1 条回复" : "展开 \(replies.count) 条回复"
                    ) {
                        expandedThreadIDs.insert(root.id)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ReviewRowInteractionModifier(
            review: root,
            currentUserName: currentUserName,
            onDelete: { delete(root) }
        ))
        .modifier(PlatformReviewsListRowModifier(enabled: usesListStyling))
        .padding(.horizontal, usesListStyling ? 0 : PlatformMetrics.contentInset)
        .padding(.vertical, usesListStyling ? 0 : PlatformConversationListRow.verticalInset)
    }

    @ViewBuilder
    private func threadToggleButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(PlatformListTypography.footnote)
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, threadToggleLeadingInset)
    }

    private var threadToggleLeadingInset: CGFloat {
        switch layout {
        case .sheetList, .embedded:
            dynamicTypeSize.commentThreadReplyLeadingInset
        case .formRows:
            0
        }
    }

    @ViewBuilder
    private func reviewContent(_ review: PlatformReview, isReply: Bool) -> some View {
        if review.hasRating, !isReply {
            PlatformReviewRatedCard(
                review: review,
                usesFormRowStyle: usesListStyling,
                isLiked: review.isLiked,
                onLike: { toggleLike(review) },
                onDislike: { toggleDislike(review) },
                onReply: { beginReply(to: review) }
            )
            .contextMenu {
                Button("回复", systemImage: "arrowshape.turn.up.left") {
                    beginReply(to: review)
                }
                if review.isOwned(by: currentUserName) {
                    Button("删除", systemImage: "trash", role: .destructive) {
                        delete(review)
                    }
                }
            }
        } else {
            CommunityCommentRow(
                comment: review.asCommunityComment,
                style: commentRowStyle,
                isReply: isReply,
                showsLike: true,
                isLiked: review.isLiked,
                isDisliked: review.isDisliked,
                showsTranslate: showsTranslate,
                contentOwnerName: contentOwnerName,
                ownerBadgeTitle: ownerBadgeTitle,
                onLike: { toggleLike(review) },
                onDislike: { toggleDislike(review) },
                onReply: { beginReply(to: review) },
                onTranslate: { onTranslate?(review) }
            )
            .contextMenu {
                Button("回复", systemImage: "arrowshape.turn.up.left") {
                    beginReply(to: review)
                }
                if review.isOwned(by: currentUserName) {
                    Button("删除", systemImage: "trash", role: .destructive) {
                        delete(review)
                    }
                }
            }
        }
    }

    private var bottomComposer: some View {
        PlatformMessageComposerBar(
            draft: draftBinding,
            placeholder: replyTarget == nil
                ? placeholder
                : "回复 \(replyTarget?.author ?? "")…",
            isEnabled: true,
            canSend: canSend,
            isFocused: $focused,
            replyPreview: replyTarget.map { ($0.author, $0.text) },
            onCancelReply: { replyTarget = nil },
            onSend: send
        )
    }

    @ViewBuilder
    private var inlineComposerRow: some View {
        if showsInlineComposer {
            TextField(placeholder, text: draftBinding, axis: .vertical)
                .lineLimit(1...4)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit(send)
                .platformMessagesSeparatorsHidden()
        }
    }

    private func reload() {
        reviews = PlatformReviewsStore.reviews(for: target)
    }

    private func beginReply(to review: PlatformReview) {
        replyTarget = review
        focused = true
    }

    private func toggleLike(_ review: PlatformReview) {
        PlatformReviewsStore.toggleLike(reviewID: review.id, target: target)
        reload()
        onChanged()
    }

    private func toggleDislike(_ review: PlatformReview) {
        PlatformReviewsStore.toggleDislike(reviewID: review.id, target: target)
        reload()
        onChanged()
    }

    private func send() {
        let outcome = PlatformReviewSubmission.submit(
            draft,
            target: target,
            author: currentUserName,
            parent: replyTarget
        )
        if let blockedWord = outcome.blockedWord {
            self.blockedWord = blockedWord
            return
        }
        if let parentID = outcome.expandedParentID {
            expandedThreadIDs.insert(parentID)
        }
        draft = ""
        replyTarget = nil
        focused = false
        reload()
        onChanged()
    }

    private func delete(_ review: PlatformReview) {
        if replyTarget?.id == review.id { replyTarget = nil }
        PlatformReviewsStore.delete(reviewID: review.id, target: target, author: currentUserName)
        reload()
        onChanged()
    }
}

// MARK: - External composer (社区详情底栏)

/// 与 `PlatformReviewsCommentsHost` 共用 draft / reply 状态的底栏输入。
struct PlatformReviewsCommentComposer: View {
    let target: PlatformReviewTarget
    let currentUserName: String
    @Binding var draft: String
    @Binding var replyTarget: PlatformReview?
    var placeholder: String
    var onChanged: () -> Void = {}

    @State private var blockedWord: String?
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        PlatformMessageComposerBar(
            draft: $draft,
            placeholder: replyTarget == nil
                ? placeholder
                : "回复 \(replyTarget?.author ?? "")…",
            isEnabled: true,
            canSend: canSend,
            isFocused: $focused,
            replyPreview: replyTarget.map { ($0.author, $0.text) },
            onCancelReply: { replyTarget = nil },
            onSend: send
        )
        .alert("评论需要修改", isPresented: Binding(
            get: { blockedWord != nil },
            set: { if !$0 { blockedWord = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(blockedWord ?? "")
        }
    }

    private func send() {
        let outcome = PlatformReviewSubmission.submit(
            draft,
            target: target,
            author: currentUserName,
            parent: replyTarget
        )
        if let blockedWord = outcome.blockedWord {
            self.blockedWord = blockedWord
            return
        }
        draft = ""
        replyTarget = nil
        focused = false
        onChanged()
    }
}

// MARK: - Submission helper

@MainActor
private enum PlatformReviewSubmission {
    struct Outcome {
        var blockedWord: String?
        var expandedParentID: UUID?
    }

    static func submit(
        _ text: String,
        target: PlatformReviewTarget,
        author: String,
        parent: PlatformReview?
    ) -> Outcome {
        if let error = PlatformReviewsStore.add(
            text,
            target: target,
            author: author,
            parent: parent
        ) {
            return Outcome(blockedWord: error, expandedParentID: nil)
        }
        let expandedParentID = parent?.parentID ?? parent?.id
        return Outcome(blockedWord: nil, expandedParentID: expandedParentID)
    }
}

// MARK: - Rated tab (companion)

struct PlatformReviewsRatedTab: View {
    let companion: PaidCompanion
    let currentUserName: String
    var onChanged: () -> Void = {}

    @State private var filter: PlatformReviewFilter = .all

    private var target: PlatformReviewTarget {
        .companion(companion.id)
    }

    private var stats: PlatformReviewStats {
        PlatformReviewsStore.stats(for: target)
    }

    var body: some View {
        Section {
            PlatformReviewsCommentsHost(
                target: target,
                currentUserName: currentUserName,
                layout: .formRows,
                contentOwnerName: companion.profile.nickname,
                ownerBadgeTitle: "陪玩",
                emptyTitle: stats.total == 0
                    ? BuddyDetailCopy.reviewsEmpty
                    : BuddyDetailCopy.reviewsFilteredEmpty,
                emptyHint: BuddyDetailCopy.reviewsFooter,
                placeholder: BuddyDetailCopy.reviewsComposerPlaceholder,
                companionFilter: stats.total > 0 ? $filter : nil,
                companionStats: stats.total > 0 ? stats : nil,
                onChanged: onChanged
            )
        } header: {
            PlatformReviewsHeader(count: stats.total)
        } footer: {
            Text(BuddyDetailCopy.reviewsFooter)
        }
    }
}

private struct FormAccessoryRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .platformMessagesSeparatorsHidden()
    }
}

private struct PlatformReviewsListRowModifier: ViewModifier {
    var enabled = true

    func body(content: Content) -> some View {
        if enabled {
            content.platformMessagesSeparatorsHidden()
        } else {
            content
        }
    }
}

private struct ReviewRowInteractionModifier: ViewModifier {
    let review: PlatformReview
    let currentUserName: String
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if review.isOwned(by: currentUserName) {
                    Button("删除", role: .destructive, action: onDelete)
                }
            }
    }
}

private struct OptionalListRowBackgroundModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .listRowBackground(Color.clear)
                .platformMessagesSeparatorsHidden()
        } else {
            content
        }
    }
}
