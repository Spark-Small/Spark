import CoordinateDomain
import CoordinateModels
import XCTest

final class ActivitiesParticipationUseCaseTests: XCTestCase {
    private let user = "测试用户"
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testJoinActivityIncrementsJoinedCount() {
        let activityID = UUID()
        var activities = [
            Activity(
                id: activityID,
                title: "局",
                category: .food,
                location: "成都",
                date: now.addingTimeInterval(3600),
                capacity: 4,
                joined: 1,
                hostName: "Host",
                summary: "s",
                fee: "免费",
                tags: []
            )
        ]
        var joinedIDs = Set<UUID>()
        var waitlistIDs = Set<UUID>()
        var notifiedIDs = Set<UUID>()

        let result = JoinActivityUseCase().execute(
            activityID: activityID,
            activities: &activities,
            joinedIDs: &joinedIDs,
            waitlistIDs: &waitlistIDs,
            waitlistSpotNotifiedIDs: &notifiedIDs,
            currentUserName: user,
            now: now
        )

        if case .success = result {
            // expected
        } else {
            XCTFail("expected success, got \(result)")
        }
        XCTAssertEqual(activities[0].joined, 2)
        XCTAssertTrue(joinedIDs.contains(activityID))
        XCTAssertTrue(activities[0].participantNames.contains(user))
    }

    func testJoinFailsWhenFull() {
        let activityID = UUID()
        var activities = [
            Activity(
                id: activityID,
                title: "满",
                category: .food,
                location: "成都",
                date: now.addingTimeInterval(3600),
                capacity: 1,
                joined: 1,
                hostName: "Host",
                summary: "s",
                fee: "免费",
                tags: []
            )
        ]
        var joinedIDs = Set<UUID>()
        var waitlistIDs = Set<UUID>()
        var notifiedIDs = Set<UUID>()

        let result = JoinActivityUseCase().execute(
            activityID: activityID,
            activities: &activities,
            joinedIDs: &joinedIDs,
            waitlistIDs: &waitlistIDs,
            waitlistSpotNotifiedIDs: &notifiedIDs,
            currentUserName: user,
            now: now
        )

        if case .failure(.alreadyFull) = result {
            // expected
        } else {
            XCTFail("expected alreadyFull, got \(result)")
        }
    }

    func testLeaveOpensSpotForWaitlistEvaluation() {
        let activityID = UUID()
        var activities = [
            Activity(
                id: activityID,
                title: "满员局",
                category: .interestSocial,
                location: "测试",
                date: now.addingTimeInterval(7200),
                capacity: 2,
                joined: 2,
                hostName: "Host",
                summary: "s",
                fee: "免费",
                tags: [],
                participantNames: ["A", user]
            )
        ]
        var joinedIDs = Set([activityID])
        var waitlistNotified = Set<UUID>()

        if case .success = LeaveActivityUseCase().execute(
            activityID: activityID,
            activities: &activities,
            joinedIDs: &joinedIDs,
            currentUserName: user
        ) {
            // expected
        } else {
            XCTFail("expected leave success")
        }
        XCTAssertEqual(activities[0].joined, 1)

        let effect = EvaluateWaitlistSpotUseCase().execute(
            activityID: activityID,
            activity: activities[0],
            isOnWaitlist: true,
            waitlistSpotNotifiedIDs: &waitlistNotified,
            now: now
        )
        XCTAssertEqual(effect, .notify(activityID: activityID, title: "满员局"))
    }

    func testRepairSnapshotPreservesUserCreatedActivities() {
        let seedID = UUID()
        let userID = UUID()
        let seed = ActivitiesSnapshot(
            activities: [
                Activity(
                    id: seedID,
                    title: "种子",
                    category: .food,
                    location: "A",
                    date: now.addingTimeInterval(7200),
                    capacity: 10,
                    joined: 2,
                    hostName: "Host",
                    summary: "s",
                    fee: "免费",
                    tags: []
                )
            ],
            joinedIDs: [seedID],
            favoriteIDs: [],
            waitlistIDs: []
        )
        let previous = ActivitiesSnapshot(
            activities: seed.activities + [
                Activity(
                    id: userID,
                    title: "自建",
                    category: .outdoorSports,
                    location: "B",
                    date: now.addingTimeInterval(3600),
                    capacity: 5,
                    joined: 1,
                    hostName: user,
                    summary: "u",
                    fee: "免费",
                    tags: []
                )
            ],
            joinedIDs: [userID],
            favoriteIDs: [userID],
            waitlistIDs: [userID]
        )

        let repaired = RepairActivitiesSnapshotUseCase().execute(seed: seed, previous: previous)

        XCTAssertTrue(repaired.activities.contains(where: { $0.id == userID }))
        // 用户取消后不得因 seed 再被静默报名；只保留 previous 的参加态。
        XCTAssertFalse(repaired.joinedIDs.contains(seedID))
        XCTAssertTrue(repaired.joinedIDs.contains(userID))
        XCTAssertTrue(repaired.favoriteIDs.contains(userID))
    }
}
