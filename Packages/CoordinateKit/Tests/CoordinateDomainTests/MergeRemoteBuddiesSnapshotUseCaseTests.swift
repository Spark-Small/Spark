import CoordinateDomain
import CoordinateModels
import XCTest

final class MergeRemoteBuddiesSnapshotUseCaseTests: XCTestCase {
    private let merge = MergeRemoteBuddiesSnapshotUseCase()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testEmptyRemoteDoesNotWipeLocalBookingsOrClubs() {
        let clubID = UUID()
        let bookingID = UUID()
        let previous = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [
                BuddyBookingRecord(
                    id: bookingID,
                    companionNickname: "阿川",
                    hours: 2,
                    scheduledAt: now.addingTimeInterval(3600),
                    bookedAt: now,
                    priceText: "¥100",
                    status: .pendingConfirm
                )
            ],
            clubs: [makeClub(id: clubID, name: "夜骑群")],
            joinedCircleIDs: [clubID],
            joinedCircleNames: ["夜骑群"],
            joinedGuildNames: ["本地工会"],
            membershipPrefs: ["circle:夜骑群": .fresh(at: now)]
        )
        let remote = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            clubs: [],
            joinedCircleIDs: [],
            joinedCircleNames: [],
            joinedGuildNames: [],
            membershipPrefs: [:]
        )

        let merged = merge.execute(remote: remote, previous: previous)

        XCTAssertEqual(merged.bookingRecords.map(\.id), [bookingID])
        XCTAssertEqual(merged.clubs.map(\.id), [clubID])
        XCTAssertEqual(Set(merged.joinedCircleIDs), [clubID])
        XCTAssertEqual(Set(merged.joinedCircleNames), ["夜骑群"])
        XCTAssertEqual(Set(merged.joinedGuildNames), ["本地工会"])
        XCTAssertNotNil(merged.membershipPrefs["circle:夜骑群"])
    }

    func testUserCreatedClubPreservedWhenRemoteHasOthers() {
        let localClubID = UUID()
        let remoteClubID = UUID()
        let previous = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            clubs: [makeClub(id: localClubID, name: "我的局")],
            joinedCircleIDs: [localClubID],
            joinedCircleNames: ["我的局"]
        )
        let remote = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            clubs: [makeClub(id: remoteClubID, name: "远程局")],
            joinedCircleIDs: [remoteClubID],
            joinedCircleNames: ["远程局"]
        )

        let merged = merge.execute(remote: remote, previous: previous)

        XCTAssertEqual(Set(merged.clubs.map(\.id)), [localClubID, remoteClubID])
        XCTAssertEqual(Set(merged.joinedCircleIDs), [localClubID, remoteClubID])
        XCTAssertEqual(Set(merged.joinedCircleNames), ["我的局", "远程局"])
    }

    func testJoinedSetsAreUnion() {
        let a = UUID()
        let b = UUID()
        let previous = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            joinedCircleIDs: [a],
            joinedCircleNames: ["A"],
            joinedGuildNames: ["G1"]
        )
        let remote = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            joinedCircleIDs: [b],
            joinedCircleNames: ["B"],
            joinedGuildNames: ["G2"]
        )

        let merged = merge.execute(remote: remote, previous: previous)

        XCTAssertEqual(Set(merged.joinedCircleIDs), [a, b])
        XCTAssertEqual(Set(merged.joinedCircleNames), ["A", "B"])
        XCTAssertEqual(Set(merged.joinedGuildNames), ["G1", "G2"])
    }

    func testRemoteOnlyBookingIsAppended() {
        let localID = UUID()
        let remoteID = UUID()
        let previous = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [
                BuddyBookingRecord(
                    id: localID,
                    companionNickname: "本地",
                    hours: 1,
                    scheduledAt: now,
                    bookedAt: now,
                    priceText: "¥50",
                    status: .paid
                )
            ]
        )
        let remote = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [
                BuddyBookingRecord(
                    id: remoteID,
                    companionNickname: "远程",
                    hours: 2,
                    scheduledAt: now,
                    bookedAt: now,
                    priceText: "¥80",
                    status: .pendingConfirm
                )
            ]
        )

        let merged = merge.execute(remote: remote, previous: previous)

        XCTAssertEqual(Set(merged.bookingRecords.map(\.id)), [localID, remoteID])
    }

    private func makeClub(id: UUID, name: String) -> InterestCircle {
        InterestCircle(
            id: id,
            name: name,
            topic: "topic",
            city: "上海",
            memberCount: 1,
            weeklyActive: 1,
            tags: [],
            summary: "",
            systemImage: "person.3",
            creatorName: "我",
            createdAt: now
        )
    }
}
