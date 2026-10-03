import CoordinateDomain
import CoordinateModels
import XCTest

final class BuddyIdentityMatchingTests: XCTestCase {
    func testPrefersUserIDWhenBothPresent() {
        let a = UUID()
        let b = UUID()
        XCTAssertTrue(
            BuddyIdentityMatching.matches(
                nickname: "甲",
                userID: a,
                otherNickname: "乙",
                otherUserID: a
            )
        )
        XCTAssertFalse(
            BuddyIdentityMatching.matches(
                nickname: "甲",
                userID: a,
                otherNickname: "甲",
                otherUserID: b
            )
        )
    }

    func testFallsBackToNicknameWhenIDMissing() {
        XCTAssertTrue(
            BuddyIdentityMatching.matches(
                nickname: "Mia",
                userID: nil,
                otherNickname: "mia",
                otherUserID: nil
            )
        )
        XCTAssertFalse(
            BuddyIdentityMatching.matches(
                nickname: "Mia",
                userID: nil,
                otherNickname: "Leo",
                otherUserID: nil
            )
        )
    }

    func testStableUserIDIsDeterministic() {
        let first = BuddyIdentityMatching.stableUserID(forNickname: "林屿")
        let second = BuddyIdentityMatching.stableUserID(forNickname: "林屿")
        let other = BuddyIdentityMatching.stableUserID(forNickname: "阿川")
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, other)
    }
}

final class MergeRemoteBuddiesDiscoverCatalogTests: XCTestCase {
    private let merge = MergeRemoteBuddiesSnapshotUseCase()

    func testRemoteDiscoverCatalogReplacesPreviousWhenPresent() {
        let previousID = UUID()
        let remoteID = UUID()
        let previous = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            discoverCatalog: BuddiesDiscoverCatalog(
                freeBuddies: [
                    BuddiesDiscoverBuddyDTO(id: previousID, nickname: "旧")
                ]
            )
        )
        let remote = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            discoverCatalog: BuddiesDiscoverCatalog(
                freeBuddies: [
                    BuddiesDiscoverBuddyDTO(id: remoteID, userID: UUID(), nickname: "新")
                ]
            )
        )

        let merged = merge.execute(remote: remote, previous: previous)
        XCTAssertEqual(merged.discoverCatalog?.freeBuddies.map(\.id), [remoteID])
    }

    func testAbsentRemoteCatalogKeepsPrevious() {
        let previousID = UUID()
        let previous = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            discoverCatalog: BuddiesDiscoverCatalog(
                freeBuddies: [
                    BuddiesDiscoverBuddyDTO(id: previousID, nickname: "缓存")
                ]
            )
        )
        let remote = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            discoverCatalog: nil
        )

        let merged = merge.execute(remote: remote, previous: previous)
        XCTAssertEqual(merged.discoverCatalog?.freeBuddies.map(\.id), [previousID])
    }

    func testEmptyRemoteCatalogClearsPrevious() {
        let previous = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            discoverCatalog: BuddiesDiscoverCatalog(
                freeBuddies: [
                    BuddiesDiscoverBuddyDTO(id: UUID(), nickname: "旧")
                ]
            )
        )
        let remote = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            discoverCatalog: BuddiesDiscoverCatalog()
        )

        let merged = merge.execute(remote: remote, previous: previous)
        XCTAssertEqual(merged.discoverCatalog?.isEmpty, true)
    }
}
