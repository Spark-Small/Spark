// Module: SparkLikes — Preview helpers (forwards to SparkDesignSystem).

import SparkDesignSystem
import SwiftUI

enum LikesPreviewSupport {
    static let preferencesStore = InMemoryLikesPreferencesStore()
    static let onboardingPreferences = InMemoryLikesOnboardingPreferences()

    static func coordinator(
        repository: any LikesFeedRepository = MockLikesFeedRepository(),
        discoverMediaImageCache: DiscoverMediaImageCache = DiscoverMediaImageCache.previewInstance()
    ) -> LikesCoordinator {
        LikesCoordinator(
            repository: repository,
            preferencesStore: preferencesStore,
            onboardingPreferences: onboardingPreferences,
            discoverMediaImageCache: discoverMediaImageCache
        )
    }

    @MainActor
    static func feedViewModel(repository: any LikesFeedRepository = MockLikesFeedRepository()) -> LikesFeedViewModel {
        coordinator(repository: repository).makeFeedViewModel()
    }

    @MainActor
    static func previewRoot(
        repository: any LikesFeedRepository = MockLikesFeedRepository(),
        onOpenMatchConversation: @escaping LikesOpenConversationHandler = { _, _, _ in }
    ) -> LikesRootView {
        LikesRootView(
            coordinator: coordinator(repository: repository),
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
