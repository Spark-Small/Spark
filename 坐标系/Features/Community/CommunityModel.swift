//
//  CommunityModel.swift
//  坐标系
//

import Foundation
import Observation
import UIKit

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
    private let repository: CommunityRepository
    @ObservationIgnored private var persistenceGeneration: Int
    @ObservationIgnored private var persistTask: Task<Void, Never>?

    init(currentUserName: String? = nil, repository: CommunityRepository? = nil) {
        let resolvedRepository = repository ?? LocalCommunityRepository()
        self.repository = resolvedRepository
        let snapshot = resolvedRepository.load()
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
        persistenceGeneration = resolvedRepository.currentPersistenceGeneration()
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

    func toggleLike(_ id: CommunityPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        if likedIDs.contains(id) {
            likedIDs.remove(id)
            posts[index].likeCount = max(posts[index].likeCount - 1, 0)
            posts[index].likerNames.removeAll { $0 == currentUserName }
        } else {
            likedIDs.insert(id)
            posts[index].likeCount += 1
            if !posts[index].likerNames.contains(currentUserName) {
                posts[index].likerNames.insert(currentUserName, at: 0)
            }
        }
        persist()
    }

    func toggleRepost(_ id: CommunityPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        if repostedIDs.contains(id) {
            repostedIDs.remove(id)
            posts[index].repostCount = max(posts[index].repostCount - 1, 0)
            posts.removeAll { $0.repostedFromID == id && $0.author == currentUserName }
            persist()
        } else {
            createRepost(of: id, quote: nil)
        }
    }

    func createRepost(of id: CommunityPost.ID, quote: String?) {
        guard let original = post(id: id) else { return }
        if !repostedIDs.contains(id), let index = posts.firstIndex(where: { $0.id == id }) {
            repostedIDs.insert(id)
            posts[index].repostCount += 1
        }
        let quoteTrimmed = quote?.trimmingCharacters(in: .whitespacesAndNewlines)
        posts.insert(
            CommunityPost(
                id: UUID(),
                author: currentUserName,
                title: "",
                body: quoteTrimmed?.isEmpty == false
                    ? (quoteTrimmed ?? "")
                    : original.body,
                tags: original.tags,
                likeCount: 0,
                commentCount: 0,
                repostCount: 0,
                shareCount: 0,
                postedAt: .now,
                isPinned: false,
                photoSeeds: [],
                photoHue: original.photoHue,
                localPhotoNames: [],
                relatedActivityTitle: original.relatedActivityTitle,
                relatedActivityID: original.relatedActivityID,
                comments: [],
                likerNames: [],
                repostedFromID: original.id,
                quoteText: quoteTrimmed?.isEmpty == false ? quoteTrimmed : nil
            ),
            at: 0
        )
        persist()
    }

    func saveBookmark(_ id: CommunityPost.ID, collection: String) {
        bookmarkedIDs.insert(id)
        bookmarkCollections[id] = collection
        persist()
    }

    func removeBookmark(_ id: CommunityPost.ID) {
        bookmarkedIDs.remove(id)
        bookmarkCollections[id] = nil
        persist()
    }

    func recordShare(_ id: CommunityPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[index].shareCount += 1
        persist()
    }

    func shareExternally(_ id: CommunityPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        let text = posts[index].shareText
        posts[index].shareCount += 1
        persist()

        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }

        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        activity.popoverPresentationController?.sourceView = presenter.view
        presenter.present(activity, animated: true)
    }

    func publish(
        body: String,
        tags: [String],
        relatedActivityTitle: String?,
        relatedActivityID: UUID? = nil,
        localPhotoNames: [String]
    ) -> CommunityPublishResult {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return .invalid }
        if let word = ContentModeration.containsSensitive(trimmedBody) {
            return .blocked(word)
        }

        let seedBase = Int.random(in: 1000...9000)
        let postID = UUID()
        posts.insert(
            CommunityPost(
                id: postID,
                author: currentUserName,
                title: "",
                body: trimmedBody,
                tags: tags,
                likeCount: 0,
                commentCount: 0,
                repostCount: 0,
                shareCount: 0,
                postedAt: .now,
                isPinned: false,
                photoSeeds: localPhotoNames.isEmpty ? [seedBase] : [],
                photoHue: Double.random(in: 0...1),
                localPhotoNames: localPhotoNames,
                relatedActivityTitle: relatedActivityTitle,
                relatedActivityID: relatedActivityID,
                comments: [],
                likerNames: []
            ),
            at: 0
        )
        isComposing = false
        pendingComposeBody = nil
        pendingRelatedActivityTitle = nil
        pendingRelatedActivityID = nil
        persist()
        return .published(postID)
    }

    func syncComments(for postID: CommunityPost.ID) {
        CommunityCommentsStore.syncCommentCount(for: postID, in: &posts)
        bumpComments()
        persist()
    }

    func deletePost(_ id: CommunityPost.ID) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == id }),
              isOwnPost(posts[index]) else { return false }
        for name in posts[index].localPhotoNames {
            CommunityPhotoStore.delete(named: name)
        }
        CommunityCommentsStore.removeAll(for: id)
        likedIDs.remove(id)
        repostedIDs.remove(id)
        bookmarkedIDs.remove(id)
        bookmarkCollections[id] = nil
        reportedIDs.remove(id)
        posts.remove(at: index)
        persist()
        return true
    }

    func reportPost(_ id: CommunityPost.ID, reason: String) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return false }
        posts[index].reportCount += 1
        reportedIDs.insert(id)
        persist()
        return true
    }

    func reloadFromRepository() async {
        guard let snapshot = try? await repository.loadAsync() else { return }
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
        if CommunityCommentsStore.bootstrap(posts: &posts, likedCommentIDs: likedCommentIDs) {
            likedCommentIDs = []
            bumpComments()
            persist()
        }
    }

    func discardPendingPersistence() async {
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    private func persist() {
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
        persistTask = Task {
            _ = await previousTask?.result
            guard !Task.isCancelled else { return }
            try? await repository.replaceAsync(with: snapshot, generation: generation)
        }
    }

    private func bumpComments() {
        commentRevision += 1
    }

}
