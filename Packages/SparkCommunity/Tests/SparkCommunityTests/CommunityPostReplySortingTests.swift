// Module: SparkCommunityTests — Reply sorting for linked-activity threads.

@testable import SparkCommunity
import Foundation
import Testing

struct CommunityPostReplySortingTests {
    @Test func participantsFirstPlacesAttendeesAheadOfNewerNonParticipants() {
        let participant = CommunityPostReply(
            id: "r_participant",
            body: "Great recap",
            authorDisplayName: "Sam",
            createdAt: Date().addingTimeInterval(-3_600),
            relationshipToViewer: .attendedLinkedActivity
        )
        let newer = CommunityPostReply(
            id: "r_newer",
            body: "Looks fun",
            authorDisplayName: "Alex",
            createdAt: Date().addingTimeInterval(-900)
        )
        let sorted = CommunityPostReplySorting.sorted(
            [newer, participant],
            mode: .participantsFirst
        )
        #expect(sorted.map(\.id) == ["r_participant", "r_newer"])
    }

    @Test func newestSortsByCreatedAtDescending() {
        let older = CommunityPostReply(
            id: "r_old",
            body: "Old",
            authorDisplayName: "A",
            createdAt: Date().addingTimeInterval(-10_000)
        )
        let newer = CommunityPostReply(
            id: "r_new",
            body: "New",
            authorDisplayName: "B",
            createdAt: Date().addingTimeInterval(-1_000)
        )
        let sorted = CommunityPostReplySorting.sorted([older, newer], mode: .newest)
        #expect(sorted.map(\.id) == ["r_new", "r_old"])
    }
}
