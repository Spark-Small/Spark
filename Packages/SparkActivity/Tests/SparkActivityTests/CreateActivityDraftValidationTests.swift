// Module: SparkActivityTests

import SparkActivity
import Testing

struct CreateActivityDraftValidationTests {
    @Test func emptyTitleThrows() {
        let draft = CreateActivityDraft(title: "   ", description: "Desc", locationName: "Park")
        #expect(throws: ActivityError.emptyInput) {
            try CreateActivityDraft.validate(draft)
        }
    }

    @Test func titleTooLongThrows() {
        let draft = CreateActivityDraft(
            title: String(repeating: "a", count: CreateActivityDraft.maxTitleLength + 1),
            description: "Desc",
            locationName: "Park"
        )
        let error = #expect(throws: ActivityError.self) {
            try CreateActivityDraft.validate(draft)
        }
        #expect(error == .fieldTooLong(field: .title))
    }

    @Test func validDraftPasses() throws {
        let draft = CreateActivityDraft(title: "Hike", description: "Trail", locationName: "North gate")
        try CreateActivityDraft.validate(draft)
    }
}
