//
//  ActivitiesHostingUseCaseTests.swift
//  CoordinateDomainTests
//

import CoordinateDomain
import CoordinateModels
import XCTest

final class ActivitiesHostingUseCaseTests: XCTestCase {
    private let host = "主办"
    private let hostID = UUID()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testPublishInsertsActivityAndJoinsHost() {
        var activities: [Activity] = []
        var joined = Set<UUID>()
        let draft = PublishActivityDraft(
            title: "新局",
            category: .food,
            location: "成都",
            date: now.addingTimeInterval(3600),
            capacity: 6,
            fee: "",
            freeFeeLabel: "免费",
            summary: "一起吃饭",
            tags: [],
            localCoverName: nil,
            distanceKM: 1.2,
            latitude: nil,
            longitude: nil,
            hostName: host,
            hostUserID: hostID
        )

        let result = PublishActivityUseCase().execute(
            draft: draft,
            activities: &activities,
            joinedIDs: &joined
        )

        guard case .success(let id) = result else {
            return XCTFail("expected success, got \(result)")
        }
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].id, id)
        XCTAssertEqual(activities[0].hostUserID, hostID)
        XCTAssertEqual(activities[0].fee, "免费")
        XCTAssertTrue(joined.contains(id))
    }

    func testCancelRequiresHost() {
        let id = UUID()
        var activities = [
            Activity(
                id: id,
                title: "局",
                category: .food,
                location: "成都",
                date: now.addingTimeInterval(3600),
                capacity: 4,
                joined: 1,
                hostName: host,
                summary: "s",
                fee: "免费",
                tags: [],
                hostUserID: hostID
            )
        ]
        var joined: Set<UUID> = [id]
        var favorites = Set<UUID>()
        var waitlist = Set<UUID>()

        let denied = CancelActivityUseCase().execute(
            activityID: id,
            activities: &activities,
            joinedIDs: &joined,
            favoriteIDs: &favorites,
            waitlistIDs: &waitlist,
            hostName: "别人",
            hostUserID: UUID()
        )
        XCTAssertEqual(denied, .failure(.notHost))
        XCTAssertEqual(activities.count, 1)

        let ok = CancelActivityUseCase().execute(
            activityID: id,
            activities: &activities,
            joinedIDs: &joined,
            favoriteIDs: &favorites,
            waitlistIDs: &waitlist,
            hostName: host,
            hostUserID: hostID
        )
        XCTAssertEqual(ok, .success(CancelActivityResult(coverName: nil)))
        XCTAssertTrue(activities.isEmpty)
    }

    func testMergeRemotePreservesUserCreatedAndMembership() {
        let seedID = UUID()
        let remoteID = UUID()
        let userCreatedID = UUID()
        let previous = ActivitiesSnapshot(
            activities: [
                Activity(
                    id: seedID,
                    title: "旧种子",
                    category: .food,
                    location: "A",
                    date: now.addingTimeInterval(3600),
                    capacity: 4,
                    joined: 1,
                    hostName: "H",
                    summary: "s",
                    fee: "免费",
                    tags: []
                ),
                Activity(
                    id: userCreatedID,
                    title: "我发的",
                    category: .food,
                    location: "B",
                    date: now.addingTimeInterval(7200),
                    capacity: 4,
                    joined: 1,
                    hostName: host,
                    summary: "s",
                    fee: "免费",
                    tags: [],
                    hostUserID: hostID
                )
            ],
            joinedIDs: [userCreatedID, seedID],
            favoriteIDs: [userCreatedID]
        )
        let remote = ActivitiesSnapshot(
            activities: [
                Activity(
                    id: remoteID,
                    title: "远程",
                    category: .food,
                    location: "C",
                    date: now.addingTimeInterval(5400),
                    capacity: 8,
                    joined: 0,
                    hostName: "Remote",
                    summary: "s",
                    fee: "免费",
                    tags: []
                )
            ],
            joinedIDs: [],
            favoriteIDs: []
        )

        let merged = MergeRemoteActivitiesCatalogUseCase().execute(
            remote: remote,
            previous: previous,
            knownSeedIDs: [seedID]
        )

        let ids = Set(merged.activities.map(\.id))
        XCTAssertTrue(ids.contains(remoteID))
        XCTAssertTrue(ids.contains(userCreatedID))
        XCTAssertFalse(ids.contains(seedID))
        XCTAssertEqual(Set(merged.joinedIDs), [userCreatedID])
        XCTAssertEqual(Set(merged.favoriteIDs), [userCreatedID])
    }
}
