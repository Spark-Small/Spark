//
//  InterestSelectionLimitsTests.swift
//  坐标系Tests
//
//  兴趣选择门槛、草稿、登出清理。
//

import XCTest
@testable import 坐标系

final class InterestSelectionLimitsTests: XCTestCase {
    func testMeetsMinimumAndMaximumBounds() {
        XCTAssertFalse(InterestSelectionLimits.meetsMinimum(0))
        XCTAssertFalse(InterestSelectionLimits.meetsMinimum(2))
        XCTAssertTrue(InterestSelectionLimits.meetsMinimum(3))
        XCTAssertTrue(InterestSelectionLimits.meetsMinimum(8))

        XCTAssertTrue(InterestSelectionLimits.canSelectMore(0))
        XCTAssertTrue(InterestSelectionLimits.canSelectMore(7))
        XCTAssertFalse(InterestSelectionLimits.canSelectMore(8))
        XCTAssertTrue(InterestSelectionLimits.isAtMaximum(8))
        XCTAssertFalse(InterestSelectionLimits.isAtMaximum(7))
    }

    func testNormalizedCustomTagTrimsAndCapsLength() {
        XCTAssertEqual(InterestSelectionLimits.normalizedCustomTag("  汉服  "), "汉服")
        XCTAssertEqual(InterestSelectionLimits.normalizedCustomTag("汉服，滑板"), "汉服滑板")
        let long = String(repeating: "啊", count: 20)
        XCTAssertEqual(
            InterestSelectionLimits.normalizedCustomTag(long).count,
            InterestSelectionLimits.customTagMaxCharacters
        )
    }

    func testProgressTextOmitsYixuanPrefix() {
        XCTAssertEqual(
            InterestSelectionLimits.progressText(count: 0),
            "请至少选择 \(InterestSelectionLimits.minimum) 项"
        )
        XCTAssertEqual(
            InterestSelectionLimits.progressText(count: 2),
            "2/8 · 再选 1 项即可开启"
        )
        XCTAssertEqual(
            InterestSelectionLimits.progressText(count: 5),
            "5/8 · 还可以再选 3 项"
        )
        XCTAssertEqual(
            InterestSelectionLimits.progressText(count: 8),
            "已满 8 项，取消后再换也可以"
        )
        XCTAssertFalse(InterestSelectionLimits.progressText(count: 3).contains("已选"))
    }

    func testCTAGateRequiresMinimumInterests() {
        XCTAssertFalse(InterestSelectionLimits.meetsMinimum(["徒步", "探店"].count))
        XCTAssertTrue(InterestSelectionLimits.meetsMinimum(["徒步", "探店", "桌游"].count))
    }

    func testDraftRoundTripAndClear() {
        let userID = UUID()
        InterestSelectionDraftStore.clear(userID: userID)
        defer { InterestSelectionDraftStore.clear(userID: userID) }

        XCTAssertNil(InterestSelectionDraftStore.load(userID: userID))
        InterestSelectionDraftStore.save(["徒步", "探店"], userID: userID)
        XCTAssertEqual(InterestSelectionDraftStore.load(userID: userID), ["徒步", "探店"])
        InterestSelectionDraftStore.clear(userID: userID)
        XCTAssertNil(InterestSelectionDraftStore.load(userID: userID))
    }

    func testCustomTagPlacementRoundTripAndClear() {
        let userID = UUID()
        InterestCustomTagPlacementStore.clear(userID: userID)
        defer { InterestCustomTagPlacementStore.clear(userID: userID) }

        XCTAssertTrue(InterestCustomTagPlacementStore.load(userID: userID).isEmpty)
        InterestCustomTagPlacementStore.save(
            ["汉服": "interestSocial", "滑板": "outdoorSports"],
            userID: userID
        )
        XCTAssertEqual(
            InterestCustomTagPlacementStore.load(userID: userID)["汉服"],
            "interestSocial"
        )
        XCTAssertEqual(
            InterestCustomTagPlacementStore.load(userID: userID)["滑板"],
            "outdoorSports"
        )
        InterestCustomTagPlacementStore.clear(userID: userID)
        XCTAssertTrue(InterestCustomTagPlacementStore.load(userID: userID).isEmpty)
    }

    @MainActor
    func testSignOutClearsInterestSelectionAndDraft() async {
        let userID = LocalUserIdentity.current
        InterestSelectionDraftStore.save(["徒步", "探店", "桌游"], userID: userID)
        defer { InterestSelectionDraftStore.clear(userID: userID) }

        let repos = AppRepositories.inMemoryForTests(
            profile: ProfileSnapshot(
                user: SampleData.currentUser,
                hasCompletedOnboarding: true,
                blockedUserNames: [],
                moderationTickets: []
            )
        )
        let app = AppDependencies.inMemoryForTests(repositories: repos).makeAppModel()
        XCTAssertTrue(app.hasCompletedInterestSelection)

        InterestCustomTagPlacementStore.save(["汉服": "freeform"], userID: userID)
        await app.signOutLocally()

        XCTAssertFalse(app.hasCompletedInterestSelection)
        XCTAssertNil(InterestSelectionDraftStore.load(userID: userID))
        XCTAssertTrue(InterestCustomTagPlacementStore.load(userID: userID).isEmpty)
        XCTAssertFalse(app.auth.isSignedIn)
    }

    @MainActor
    func testCompleteInterestSelectionIsIdempotent() {
        let repos = AppRepositories.inMemoryForTests(
            profile: ProfileSnapshot(
                user: SampleData.currentUser,
                hasCompletedOnboarding: false,
                blockedUserNames: [],
                moderationTickets: []
            )
        )
        let app = AppDependencies.inMemoryForTests(repositories: repos).makeAppModel()
        XCTAssertFalse(app.hasCompletedInterestSelection)

        app.completeInterestSelection(interests: ["徒步", "探店", "桌游"])
        XCTAssertTrue(app.hasCompletedInterestSelection)
        XCTAssertEqual(Set(app.user.interests), Set(["徒步", "探店", "桌游"]))

        app.completeInterestSelection(interests: ["徒步", "探店", "桌游", "咖啡"])
        XCTAssertTrue(app.hasCompletedInterestSelection)
        XCTAssertEqual(Set(app.user.interests), Set(["徒步", "探店", "桌游", "咖啡"]))
    }
}
