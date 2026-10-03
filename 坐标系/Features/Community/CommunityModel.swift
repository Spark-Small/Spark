//
//  CommunityModel.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

enum CommunityPublishResult: Equatable {
    case published(CommunityPost.ID)
    case blocked(String)
    case invalid
}

@MainActor
@Observable
final class CommunityModel {
    var posts: [CommunityPost]
    var presentation = CommunityPresentationStore()
    var likedIDs: Set<UUID>
    var repostedIDs: Set<UUID>
    var bookmarkedIDs: Set<UUID>
    var bookmarkCollections: [UUID: String]
    var reportedIDs: Set<UUID>
    var likedCommentIDs: Set<UUID>
    var currentUserName: String
    var blockedUserNames: Set<String> = []
    /// 评论库变更时递增，驱动依赖 PlatformReviewsStore 的界面刷新
    private(set) var commentRevision = 0
    /// 广场加载失败文案；成功或尚未尝试时为 `nil`。
    private(set) var loadErrorMessage: String?
    let repository: any CommunityRepository
    let engagement: CommunityEngagementUseCases
    let moderation: CommunityModerationUseCases
    /// 站内通知写回（赞/转他人帖）；预览与「我的·通知」同源。
    let notificationInbox: InAppNotificationStore?
    @ObservationIgnored var persistenceGeneration: Int
    @ObservationIgnored var persistTask: Task<Void, Never>?

    var pendingComposeBody: String? {
        get { presentation.pendingComposeBody }
        set { presentation.pendingComposeBody = newValue }
    }

    var pendingRelatedActivityTitle: String? {
        get { presentation.pendingRelatedActivityTitle }
        set { presentation.pendingRelatedActivityTitle = newValue }
    }

    var pendingRelatedActivityID: UUID? {
        get { presentation.pendingRelatedActivityID }
        set { presentation.pendingRelatedActivityID = newValue }
    }

    init(
        currentUserName: String? = nil,
        repository: any CommunityRepository,
        engagement: CommunityEngagementUseCases = CommunityEngagementUseCases(),
        moderation: CommunityModerationUseCases = CommunityModerationUseCases(),
        notificationInbox: InAppNotificationStore? = nil
    ) {
        self.repository = repository
        self.engagement = engagement
        self.moderation = moderation
        self.notificationInbox = notificationInbox
        let snapshot = repository.load()
        posts = snapshot.posts
        likedIDs = Set(snapshot.likedIDs)
        repostedIDs = Set(snapshot.repostedIDs)
        bookmarkedIDs = Set(snapshot.bookmarkedIDs)
        reportedIDs = Set(snapshot.reportedIDs)
        likedCommentIDs = Set(snapshot.likedCommentIDs)
        var collections: [UUID: String] = [:]
        for (key, value) in snapshot.bookmarkCollections {
            if let id = UUID(uuidString: key) {
                collections[id] = value
            }
        }
        bookmarkCollections = collections
        // AppModel 注入资料昵称；缺省时空串，禁止静默回落 Sample 身份。
        self.currentUserName = currentUserName ?? ""
        persistenceGeneration = repository.currentPersistenceGeneration()
        if CommunityCommentsStore.bootstrap(posts: &posts, likedCommentIDs: likedCommentIDs) {
            likedCommentIDs = []
            persist()
        }
    }

    func isOwnPost(_ post: CommunityPost) -> Bool {
        post.isOwned(by: currentUserName)
    }

    var items: [CommunityPost] {
        let visible = posts.filter {
            (!reportedIDs.contains($0.id) || isOwnPost($0))
                && !blockedUserNames.contains($0.author)
        }
        return visible
            .sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.postedAt > $1.postedAt
        }
    }

    var bookmarkedPosts: [CommunityPost] {
        posts
            .filter { bookmarkedIDs.contains($0.id) }
            .sorted { $0.postedAt > $1.postedAt }
    }

    var likedPosts: [CommunityPost] {
        posts
            .filter { likedIDs.contains($0.id) }
            .sorted { $0.postedAt > $1.postedAt }
    }

    var myPosts: [CommunityPost] {
        posts
            .filter { isOwnPost($0) && $0.repostedFromID == nil }
            .sorted { $0.postedAt > $1.postedAt }
    }

    var myReposts: [CommunityPost] {
        posts
            .filter { isOwnPost($0) && $0.repostedFromID != nil }
            .sorted { $0.postedAt > $1.postedAt }
    }

    func isLiked(_ id: CommunityPost.ID) -> Bool { likedIDs.contains(id) }
    func isReposted(_ id: CommunityPost.ID) -> Bool { repostedIDs.contains(id) }
    func isBookmarked(_ id: CommunityPost.ID) -> Bool { bookmarkedIDs.contains(id) }
    func bookmarkCollection(for id: CommunityPost.ID) -> String? { bookmarkCollections[id] }
    func post(id: CommunityPost.ID) -> CommunityPost? { posts.first { $0.id == id } }

    func reloadFromRepository() async {
        do {
            let snapshot = try await repository.loadAsync()
            persistenceGeneration = repository.currentPersistenceGeneration()
            posts = snapshot.posts
            likedIDs = Set(snapshot.likedIDs)
            repostedIDs = Set(snapshot.repostedIDs)
            bookmarkedIDs = Set(snapshot.bookmarkedIDs)
            reportedIDs = Set(snapshot.reportedIDs)
            likedCommentIDs = Set(snapshot.likedCommentIDs)
            bookmarkCollections = Dictionary(
                uniqueKeysWithValues: snapshot.bookmarkCollections.compactMap { key, value in
                    guard let id = UUID(uuidString: key) else { return nil }
                    return (id, value)
                }
            )
            loadErrorMessage = nil
            if CommunityCommentsStore.bootstrap(posts: &posts, likedCommentIDs: likedCommentIDs) {
                likedCommentIDs = []
                bumpComments()
                persist()
            }
        } catch {
            loadErrorMessage = CommunityBrowseCopy.loadFailedMessage
        }
    }

    func discardPendingPersistence() async {
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    func persist() {
        let snapshot = CommunitySnapshot(
            posts: posts,
            likedIDs: Array(likedIDs),
            repostedIDs: Array(repostedIDs),
            bookmarkedIDs: Array(bookmarkedIDs),
            bookmarkCollections: Dictionary(
                uniqueKeysWithValues: bookmarkCollections.map { ($0.key.uuidString, $0.value) }
            ),
            reportedIDs: Array(reportedIDs),
            likedCommentIDs: []
        )
        let previousTask = persistTask
        let generation = persistenceGeneration
        persistTask = MainActorPersistence.chained(after: previousTask) {
            do {
                try await self.repository.replaceAsync(with: snapshot, generation: generation)
            } catch {
                assertionFailure("Community persist failed: \(error)")
                PersistenceWriteFailureReporter.record(domainKey: "community", error: error)
            }
        }
    }

    func bumpComments() {
        commentRevision += 1
    }

    func recordCommunityInbox(
        kind: String,
        title: String,
        body: String,
        postID: UUID,
        author: String
    ) {
        guard author != currentUserName else { return }
        notificationInbox?.record(
            category: .community,
            title: title,
            body: body,
            dedupeKey: CommunityEngagementNotificationKeys.dedupeKey(
                kind: kind,
                postID: postID,
                actorName: currentUserName
            ),
            communityPostID: postID,
            activityKind: kind
        )
    }

    /// 取消赞 / 取消转发：撤销同 actor·同帖·同 kind 的站内通知。
    func revokeCommunityInbox(kind: String, postID: UUID) {
        let key = CommunityEngagementNotificationKeys.dedupeKey(
            kind: kind,
            postID: postID,
            actorName: currentUserName
        )
        notificationInbox?.removeMatching(dedupeKey: key)
    }
}
