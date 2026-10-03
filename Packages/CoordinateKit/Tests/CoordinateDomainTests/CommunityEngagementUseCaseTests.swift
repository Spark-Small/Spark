//
//  CommunityEngagementUseCaseTests.swift
//  CoordinateDomainTests
//

import CoordinateDomain
import CoordinateModels
import XCTest

final class CommunityEngagementUseCaseTests: XCTestCase {
    private let engagement = CommunityEngagementUseCases()

    func testToggleLikeIdempotentRoundTrip() {
        let postID = UUID()
        var posts = [makePost(id: postID, author: "作者", likeCount: 0)]
        var liked = Set<UUID>()

        XCTAssertEqual(
            engagement.toggleLike(postID: postID, currentUserName: "我", posts: &posts, likedIDs: &liked),
            .liked(author: "作者", postID: postID)
        )
        XCTAssertEqual(posts[0].likeCount, 1)
        XCTAssertEqual(liked, [postID])

        XCTAssertEqual(
            engagement.toggleLike(postID: postID, currentUserName: "我", posts: &posts, likedIDs: &liked),
            .unliked(postID: postID)
        )
        XCTAssertEqual(posts[0].likeCount, 0)
        XCTAssertTrue(liked.isEmpty)
    }

    func testMarkRepostedIsIdempotentOnCount() {
        let postID = UUID()
        var posts = [makePost(id: postID, author: "作者", likeCount: 0, repostCount: 0)]
        var reposted = Set<UUID>()

        let first = engagement.markReposted(originalPostID: postID, posts: &posts, repostedIDs: &reposted)
        let second = engagement.markReposted(originalPostID: postID, posts: &posts, repostedIDs: &reposted)

        XCTAssertEqual(first, .reposted(author: "作者", postID: postID))
        XCTAssertEqual(second, .reposted(author: "作者", postID: postID))
        XCTAssertEqual(posts[0].repostCount, 1)
        XCTAssertEqual(reposted, [postID])
    }

    func testBookmarkSaveAndRemove() {
        let postID = UUID()
        var bookmarked = Set<UUID>()
        var collections: [UUID: String] = [:]

        engagement.saveBookmark(
            postID: postID,
            collection: "种草",
            bookmarkedIDs: &bookmarked,
            bookmarkCollections: &collections
        )
        XCTAssertEqual(bookmarked, [postID])
        XCTAssertEqual(collections[postID], "种草")

        engagement.removeBookmark(
            postID: postID,
            bookmarkedIDs: &bookmarked,
            bookmarkCollections: &collections
        )
        XCTAssertTrue(bookmarked.isEmpty)
        XCTAssertNil(collections[postID])
    }

    func testCommunityInboxDedupeKeyStable() {
        let postID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let key = CommunityEngagementNotificationKeys.dedupeKey(
            kind: "like",
            postID: postID,
            actorName: "我"
        )
        XCTAssertEqual(key, "community-like-AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE-我")
        XCTAssertEqual(
            key,
            CommunityEngagementNotificationKeys.dedupeKey(kind: "like", postID: postID, actorName: "我")
        )
    }

    private func makePost(
        id: UUID,
        author: String,
        likeCount: Int,
        repostCount: Int = 0
    ) -> CommunityPost {
        CommunityPost(
            id: id,
            author: author,
            title: "",
            body: "hi",
            tags: [],
            likeCount: likeCount,
            commentCount: 0,
            repostCount: repostCount,
            shareCount: 0,
            postedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isPinned: false,
            photoSeeds: [],
            photoHue: 0.2,
            localPhotoNames: [],
            relatedActivityTitle: nil,
            relatedActivityID: nil,
            comments: [],
            likerNames: []
        )
    }
}
