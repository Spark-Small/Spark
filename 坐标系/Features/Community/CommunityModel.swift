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
    var isComposing = false
    /// 从活动页跳转发复盘时预填正文
    var pendingComposeBody: String?
    var pendingRelatedActivityTitle: String?
    var pendingRelatedActivityID: UUID?
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
    private(set) var isRefreshing = false
    let repository: any CommunityRepository
    @ObservationIgnored var persistenceGeneration: Int
    @ObservationIgnored var persistTask: Task<Void, Never>?

    init(
        currentUserName: String? = nil,
        repository: any CommunityRepository
    ) {
        self.repository = repository
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
        self.currentUserName = currentUserName ?? SampleData.currentUser.name
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

    func likerNames(for id: CommunityPost.ID) -> [String] {
        guard let post = post(id: id) else { return [] }
        var names = post.likerNames
        if likedIDs.contains(id), !names.contains(where: { $0 == currentUserName }) {
            names.insert(currentUserName, at: 0)
        }
        if !likedIDs.contains(id) {
            names.removeAll { $0 == currentUserName }
        }
        return names
    }
    func reloadFromRepository() async {
        isRefreshing = true
        defer { isRefreshing = false }
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
            loadErrorMessage = CommunityCopy.loadFailedMessage
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

}
