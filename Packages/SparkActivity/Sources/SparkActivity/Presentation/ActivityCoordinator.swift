// Module: SparkActivity — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation

public struct ActivityCoordinator: Sendable {
    private let feedRepository: any ActivityFeedRepository
    private let blockedHostsStore: BlockedActivityHostsStore
    private let browseRepository: (any ActivityBrowseRepository)?

    public var hasBrowseCatalog: Bool { browseRepository != nil }

    public init(
        feedRepository: any ActivityFeedRepository,
        blockedHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore(),
        browseRepository: (any ActivityBrowseRepository)? = nil
    ) {
        self.feedRepository = feedRepository
        self.blockedHostsStore = blockedHostsStore
        self.browseRepository = browseRepository
    }

    @MainActor
    public func makeInboxViewModel() -> ActivityViewModel {
        ActivityViewModel(fetchActivities: FetchActivityFeedUseCase(repository: feedRepository))
    }

    @MainActor
    public func makeDetailViewModel(
        activityID: String,
        context: ActivityDetailContext = .inbox,
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onActivityUpdated: ((ActivityDetail) async -> Void)? = nil
    ) -> ActivityDetailViewModel {
        ActivityDetailViewModel(
            activityID: activityID,
            fetchDetail: FetchActivityDetailUseCase(repository: feedRepository),
            updateRSVP: UpdateActivityRSVPUseCase(repository: feedRepository),
            cancelActivity: CancelActivityUseCase(repository: feedRepository),
            reportActivity: ReportActivityUseCase(repository: feedRepository),
            joinWaitlist: JoinActivityWaitlistUseCase(repository: feedRepository),
            promoteFromWaitlist: PromoteFromWaitlistUseCase(repository: feedRepository),
            announceActivity: AnnounceActivityUseCase(repository: feedRepository),
            submitHostFeedback: SubmitHostFeedbackUseCase(repository: feedRepository),
            fetchHostActivities: FetchActivitiesByHostUseCase(repository: feedRepository),
            context: context,
            blockedHostsStore: blockedHostsStore,
            onRSVPCompleted: onRSVPCompleted,
            onActivityUpdated: onActivityUpdated
        )
    }

    @MainActor
    public func makeBrowseViewModel() -> ActivityBrowseViewModel {
        guard let browseRepository else {
            preconditionFailure("ActivityCoordinator.browseRepository is required for browse")
        }
        return ActivityBrowseViewModel(fetchBrowsePage: FetchActivityBrowsePageUseCase(repository: browseRepository))
    }

    @MainActor
    public func makeCreateViewModel(initialDraft: CreateActivityDraft? = nil) -> CreateActivityViewModel {
        let viewModel = CreateActivityViewModel(createActivity: CreateActivityUseCase(repository: feedRepository))
        if let initialDraft {
            viewModel.draft = initialDraft
        }
        return viewModel
    }

    @MainActor
    public func makeEditViewModel(activity: ActivityDetail) -> EditActivityViewModel {
        EditActivityViewModel(
            activity: activity,
            updateActivity: UpdateActivityUseCase(repository: feedRepository)
        )
    }

    public func fetchRecommendedActivity(within interval: TimeInterval = 604_800) async -> (id: String, title: String)? {
        guard let browseRepository else { return nil }
        guard let page = try? await browseRepository.fetchBrowse(
            query: ActivityBrowseQuery(startsBefore: Date().addingTimeInterval(interval))
        ),
            let item = page.items.first else {
            return nil
        }
        return (item.id, item.title)
    }

    public func fetchActivityRecap(activityID: String) async -> (title: String, scheduleLine: String)? {
        guard let detail = try? await feedRepository.fetchActivity(id: activityID) else { return nil }
        return (detail.title, detail.scheduleLine)
    }

    public func syncReminders(for detail: ActivityDetail) async {
        await ActivityLocalReminderScheduler.syncReminders(for: detail)
    }
}
