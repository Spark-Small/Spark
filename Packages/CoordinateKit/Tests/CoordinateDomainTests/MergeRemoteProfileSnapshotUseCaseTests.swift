import CoordinateDomain
import CoordinateModels
import XCTest

final class MergeRemoteProfileSnapshotUseCaseTests: XCTestCase {
    private let merge = MergeRemoteProfileSnapshotUseCase()

    func testPreservesLocalGalleryWhenRemoteEmpty() {
        let localID = UUID()
        let previous = ProfileSnapshot(
            user: AppUser(
                id: localID,
                name: "林屿",
                handle: "linyu",
                city: "上海",
                bio: "本机简介",
                joinedCount: 1,
                hostedCount: 0,
                buddyCount: 0,
                intents: [.findPeers],
                galleryLocalNames: ["local-a.jpg"]
            ),
            hasCompletedOnboarding: true,
            blockedUserNames: ["坏人"],
            followedUserNames: ["好友"]
        )
        let remote = ProfileSnapshot(
            user: AppUser(
                id: UUID(),
                name: "林屿",
                handle: "linyu",
                city: "成都",
                bio: "远程简介",
                joinedCount: 3,
                hostedCount: 1,
                buddyCount: 2,
                intents: [.joinActivities]
            ),
            hasCompletedOnboarding: false,
            blockedUserNames: [],
            followedUserNames: ["新关注"]
        )

        let merged = merge.execute(remote: remote, previous: previous)

        XCTAssertEqual(merged.user.id, localID)
        XCTAssertEqual(merged.user.city, "成都")
        XCTAssertEqual(merged.user.bio, "远程简介")
        XCTAssertEqual(merged.user.galleryLocalNames, ["local-a.jpg"])
        XCTAssertEqual(merged.user.intents, [ProfileIntent.joinActivities])
        XCTAssertTrue(merged.hasCompletedOnboarding)
        XCTAssertEqual(Set(merged.blockedUserNames), ["坏人"])
        XCTAssertEqual(Set(merged.followedUserNames), ["好友", "新关注"])
        XCTAssertEqual(merged.user.joinedCount, 3)
    }

    func testKeepsLocalPromptsWhenRemoteOmits() {
        let prompt = ProfilePrompt(promptKey: "weekPlan", answer: "本机问答")
        let previous = ProfileSnapshot(
            user: AppUser(
                name: "A",
                handle: "a",
                city: "上海",
                bio: "",
                joinedCount: 0,
                hostedCount: 0,
                buddyCount: 0,
                prompts: [prompt]
            ),
            hasCompletedOnboarding: true
        )
        let remote = ProfileSnapshot(
            user: AppUser(
                name: "A",
                handle: "a",
                city: "上海",
                bio: "远程",
                joinedCount: 0,
                hostedCount: 0,
                buddyCount: 0
            ),
            hasCompletedOnboarding: true
        )

        let merged = merge.execute(remote: remote, previous: previous)
        XCTAssertEqual(merged.user.prompts.map(\.answer), ["本机问答"])
        XCTAssertEqual(merged.user.bio, "远程")
    }
}
