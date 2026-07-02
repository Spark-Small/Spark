// Module: SparkActivityTests

import SparkActivity
import Testing

@MainActor
struct ActivityCreateTemplateStoreTests {
    @Test func saveCustomTemplateRequiresTitle() {
        let store = ActivityCreateTemplateStore(savedTemplates: [])
        let draft = CreateActivityDraft(title: "   ", locationName: "Park")
        #expect(store.saveCustom(from: draft, name: "My template") == nil)
    }

    @Test func saveAndApplyCustomTemplate() {
        let store = ActivityCreateTemplateStore(savedTemplates: [])
        var draft = CreateActivityDraft(
            title: "Coffee",
            description: "Chat",
            locationName: "Cafe",
            category: "咖啡",
            capacity: 3
        )
        #expect(store.saveCustom(from: draft, name: "Coffee template") != nil)
        draft = CreateActivityDraft()
        store.savedTemplates.first?.apply(to: &draft)
        #expect(draft.title == "Coffee")
        #expect(draft.capacity == 3)
    }

    @Test func favoriteActivityTemplateDedupes() {
        let store = ActivityCreateTemplateStore(savedTemplates: [])
        let activity = ActivityDetail(
            id: "act_1",
            title: "Hike",
            summary: "Sat",
            category: "户外",
            description: "Trail",
            startsAt: .now,
            locationName: "Park",
            hostDisplayName: "Alex",
            attendeeCount: 2,
            capacity: 6,
            rsvpStatus: .going
        )
        store.favorite(activity: activity)
        store.favorite(activity: activity)
        #expect(store.savedTemplates.count == 1)
        #expect(store.isFavorited(activityID: "act_1"))
    }
}
