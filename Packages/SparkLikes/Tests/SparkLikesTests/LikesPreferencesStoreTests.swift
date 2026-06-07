// Module: SparkLikesTests — Likes preferences persistence coverage.

@testable import SparkLikes
import Foundation
import Testing

struct LikesPreferencesStoreTests {
    @Test func inMemoryStoreRoundTripsPreferences() {
        let store = InMemoryLikesPreferencesStore()
        var prefs = store.load()
        prefs.intent = .friends
        store.save(prefs)
        #expect(store.load().intent == .friends)
    }

    @Test func inMemoryOnboardingPreferencesMarksSeen() {
        let prefs = InMemoryLikesOnboardingPreferences()
        #expect(prefs.hasSeenOnboarding == false)
        prefs.markOnboardingSeen()
        #expect(prefs.hasSeenOnboarding == true)
    }

    @Test func userDefaultsStorePersistsPreferences() throws {
        let suite = "com.spark.tests.likes.prefs.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Could not create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsLikesPreferencesStore(defaults: defaults)
        store.save(LikesPreferences(genderPreference: .opposite, intent: .friends))
        let reloaded = UserDefaultsLikesPreferencesStore(defaults: defaults)
        #expect(reloaded.load().genderPreference == .opposite)
        #expect(reloaded.load().intent == .friends)
    }
}
