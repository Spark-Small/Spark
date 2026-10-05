import CoordinateDomain
import CoordinateModels
import XCTest

final class CommunityBrowseFilteringTests: XCTestCase {
    func testFollowingAndPeopleYouFollowAreMutuallyExclusive() {
        let posts = [
            makePost(author: "我", body: "own"),
            makePost(author: "阿川", body: "followed"),
            makePost(author: "新人", body: "discover")
        ]
        let followed: Set<String> = ["阿川"]

        let following = CommunityBrowseFiltering.posts(
            posts,
            filter: .following,
            followedUserNames: followed,
            currentUserName: "我",
            joinedActivityTitles: []
        )
        let discover = CommunityBrowseFiltering.posts(
            posts,
            filter: .peopleYouFollow,
            followedUserNames: followed,
            currentUserName: "我",
            joinedActivityTitles: []
        )

        XCTAssertEqual(following.map(\.author), ["阿川"])
        XCTAssertEqual(discover.map(\.author), ["新人"])
    }

    func testPeopleYouFollowRetainsAuthorsFollowedInSession() {
        let posts = [
            makePost(author: "新人", body: "discover"),
            makePost(author: "阿川", body: "followed")
        ]
        let retained = CommunityBrowseFiltering.posts(
            posts,
            filter: .peopleYouFollow,
            followedUserNames: ["新人"],
            currentUserName: "我",
            joinedActivityTitles: [],
            retainedAuthorNames: ["新人"]
        )
        XCTAssertEqual(retained.map(\.author), ["新人"])
    }

    func testMentionMatchesJoinedActivityTitle() {
        let posts = [
            makePost(author: "路人", body: "无关", related: "夜骑局"),
            makePost(author: "路人", body: "提到我", related: nil)
        ]
        let filtered = CommunityBrowseFiltering.posts(
            posts,
            filter: .mention,
            followedUserNames: [],
            currentUserName: "我",
            joinedActivityTitles: ["夜骑局"]
        )
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.relatedActivityTitle, "夜骑局")
    }

    func testFollowCandidatesHonorsLimit() {
        let posts = (0..<6).map { makePost(author: "作者\($0)", body: "p\($0)") }
        let names = CommunityBrowseFiltering.followCandidates(
            from: posts,
            followedUserNames: [],
            currentUserName: "我",
            limit: 3
        )
        XCTAssertEqual(names.count, 3)
        XCTAssertEqual(names, ["作者0", "作者1", "作者2"])
    }

    func testCommunityNotificationMentionsBlockedAuthor() {
        XCTAssertTrue(
            CommunityBrowseFiltering.communityNotificationMentionsBlocked(
                title: "阿川 赞了你的分享",
                body: "夜骑复盘",
                blockedUserNames: ["阿川"]
            )
        )
        XCTAssertFalse(
            CommunityBrowseFiltering.communityNotificationMentionsBlocked(
                title: "路人 赞了你的分享",
                body: "夜骑复盘",
                blockedUserNames: ["阿川"]
            )
        )
    }

    func testModerationDeleteOnlyAllowsOwner() {
        let moderation = CommunityModerationUseCases()
        let postID = UUID()
        var posts = [makePost(id: postID, author: "作者", body: "hi")]
        var liked = Set<UUID>()
        var reposted = Set<UUID>()
        var bookmarked = Set<UUID>()
        var collections: [UUID: String] = [:]
        var reported = Set<UUID>()

        XCTAssertNil(
            moderation.deleteOwnPost(
                postID: postID,
                currentUserName: "他人",
                posts: &posts,
                likedIDs: &liked,
                repostedIDs: &reposted,
                bookmarkedIDs: &bookmarked,
                bookmarkCollections: &collections,
                reportedIDs: &reported
            )
        )
        XCTAssertEqual(posts.count, 1)

        let media = moderation.deleteOwnPost(
            postID: postID,
            currentUserName: "作者",
            posts: &posts,
            likedIDs: &liked,
            repostedIDs: &reposted,
            bookmarkedIDs: &bookmarked,
            bookmarkCollections: &collections,
            reportedIDs: &reported
        )
        XCTAssertNotNil(media)
        XCTAssertTrue(posts.isEmpty)
    }

    private func makePost(
        id: UUID = UUID(),
        author: String,
        body: String,
        related: String? = nil
    ) -> CommunityPost {
        CommunityPost(
            id: id,
            author: author,
            title: "",
            body: body,
            tags: [],
            likeCount: 0,
            commentCount: 0,
            repostCount: 0,
            shareCount: 0,
            postedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isPinned: false,
            photoSeeds: [],
            photoHue: 0.1,
            localPhotoNames: [],
            relatedActivityTitle: related,
            relatedActivityID: nil,
            comments: [],
            likerNames: []
        )
    }
}
