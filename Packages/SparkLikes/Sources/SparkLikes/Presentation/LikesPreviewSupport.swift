// Module: SparkLikes — Preview helpers (forwards to SparkDesignSystem).

import SparkDesignSystem
import SwiftUI

enum LikesPreviewSupport {
    static let preferencesStore = InMemoryLikesPreferencesStore()
    static let onboardingPreferences = InMemoryLikesOnboardingPreferences()

    @MainActor
    static func feedViewModel(repository: any LikesFeedRepository = MockLikesFeedRepository()) -> LikesFeedViewModel {
        LikesFeedViewModel(
            repository: repository,
            preferencesStore: preferencesStore,
            onboardingPreferences: onboardingPreferences
        )
    }

    @MainActor
    static func previewRoot(
        repository: any LikesFeedRepository = MockLikesFeedRepository(),
        discoverMediaImageCache: DiscoverMediaImageCache = DiscoverMediaImageCache(),
        onOpenMatchConversation: @escaping LikesOpenConversationHandler = { _, _, _ in }
    ) -> LikesRootView {
        LikesRootView(
            repository: repository,
            discoverMediaImageCache: discoverMediaImageCache,
            preferencesStore: preferencesStore,
            onboardingPreferences: onboardingPreferences,
            onOpenMatchConversation: onOpenMatchConversation
        )
    }

    static func darkMode<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        SparkPreviewSupport.darkMode(content)
    }

    static func accessibilityXL<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        SparkPreviewSupport.accessibilityXL(content)
    }

    static func iPadRegular<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        SparkPreviewSupport.iPadRegular(content)
    }
}
