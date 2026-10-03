import CoordinateDomain
import CoordinateModels
import XCTest

final class MergeRemoteCommunitySnapshotUseCaseTests: XCTestCase {
    private let merge = MergeRemoteCommunitySnapshotUseCase()

    func testLocalOnlyPostPreservedWhenRemoteEmpty() {
        let localID = UUID()
        let previous = CommunitySnapshot(
            posts: [makePost(id: localID, author: "我", body: "本机刚发")],
            likedIDs: [localID],
            repostedIDs: [],
            bookmarkedIDs: [],
            bookmarkCollections: [:],
            reportedIDs: [],
            likedCommentIDs: []
        )
        let remote = CommunitySnapshot(
            posts: [],
            likedIDs: [],
            repostedIDs: [],
            bookmarkedIDs: [],
            bookmarkCollections: [:],
            reportedIDs: [],
            likedCommentIDs: []
        )

        let merged = merge.execute(remote: remote, previous: previous)

        XCTAssertEqual(merged.posts.map(\.id), [localID])
        XCTAssertEqual(Set(merged.likedIDs), [localID])
    }

    func testRemotePostUpsertsAndKeepsLocalEngagementUnion() {
        let sharedID = UUID()
        let remoteOnlyID = UUID()
        let previous = CommunitySnapshot(
            posts: [makePost(id: sharedID, author: "阿川", body: "旧正文", likeCount: 3)],
            likedIDs: [sharedID],
            repostedIDs: [],
            bookmarkedIDs: [sharedID],
            bookmarkCollections: [sharedID.uuidString: "种草"],
            reportedIDs: [],
            likedCommentIDs: []
        )
        let remote = CommunitySnapshot(
            posts: [
                makePost(id: sharedID, author: "阿川", body: "新正文", likeCount: 5),
                makePost(id: remoteOnlyID, author: "远程", body: "新帖")
            ],
            likedIDs: [],
            repostedIDs: [remoteOnlyID],
            bookmarkedIDs: [],
            bookmarkCollections: [:],
            reportedIDs: [],
            likedCommentIDs: []
        )

        let merged = merge.execute(remote: remote, previous: previous)

        XCTAssertEqual(Set(merged.posts.map(\.id)), [sharedID, remoteOnlyID])
        XCTAssertEqual(merged.posts.first(where: { $0.id == sharedID })?.body, "新正文")
        XCTAssertEqual(merged.posts.first(where: { $0.id == sharedID })?.likeCount, 5)
        XCTAssertEqual(Set(merged.likedIDs), [sharedID])
        XCTAssertEqual(Set(merged.bookmarkedIDs), [sharedID])
        XCTAssertEqual(merged.bookmarkCollections[sharedID.uuidString], "种草")
        XCTAssertEqual(Set(merged.repostedIDs), [remoteOnlyID])
    }

    private func makePost(
        id: UUID,
        author: String,
        body: String,
        likeCount: Int = 0
    ) -> CommunityPost {
        CommunityPost(
            id: id,
            author: author,
            title: "",
            body: body,
            tags: [],
            likeCount: likeCount,
            commentCount: 0,
            repostCount: 0,
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
