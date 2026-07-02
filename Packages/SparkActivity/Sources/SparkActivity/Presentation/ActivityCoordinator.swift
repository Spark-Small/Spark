// Module: SparkActivity — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation
import SparkCore

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
        onActivityUpdated: ((ActivityDetail) async -> Void)? = nil,
        onHostBlocked: (() async -> Void)? = nil
    ) -> ActivityDetailViewModel {
        ActivityDetailViewModel(
            activityID: activityID,
            fetchDetail: FetchActivityDetailUseCase(repository: feedRepository),
            updateRSVP: UpdateActivityRSVPUseCase(repository: feedRepository),
            cancelActivity: CancelActivityUseCase(repository: feedRepository),
            reportActivity: ReportActivityUseCase(repository: feedRepository),
            joinWaitlist: JoinActivityWaitlistUseCase(repository: feedRepository),
            promoteFromWaitlist: PromoteFromWaitlistUseCase(repository: feedRepository),
            reviewAttendeeRSVP: ReviewAttendeeRSVPUseCase(repository: feedRepository),
            setAttendeeCoHost: SetAttendeeCoHostUseCase(repository: feedRepository),
            announceActivity: AnnounceActivityUseCase(repository: feedRepository),
            submitHostFeedback: SubmitHostFeedbackUseCase(repository: feedRepository),
            fetchHostActivities: FetchActivitiesByHostUseCase(repository: feedRepository),
            fetchFeed: FetchActivityFeedUseCase(repository: feedRepository),
            fetchBrowsePage: browseRepository.map { FetchActivityBrowsePageUseCase(repository: $0) },
            context: context,
            blockedHostsStore: blockedHostsStore,
            onRSVPCompleted: onRSVPCompleted,
            onActivityUpdated: onActivityUpdated,
            onHostBlocked: onHostBlocked
        )
    }

    @MainActor
    func makeBrowseJoinViewModel(item: ActivityItem) -> ActivityBrowseJoinViewModel {
        ActivityBrowseJoinViewModel(
            item: item,
            updateRSVP: UpdateActivityRSVPUseCase(repository: feedRepository)
        )
    }

    @MainActor
    public func makeBrowseViewModel() -> ActivityBrowseViewModel {
        guard let browseRepository else {
            preconditionFailure("ActivityCoordinator.browseRepository is required for browse")
        }
        return ActivityBrowseViewModel(
            fetchBrowsePage: FetchActivityBrowsePageUseCase(repository: browseRepository),
            blockedHostsStore: blockedHostsStore
        )
    }

    @MainActor
    public func makeCreateViewModel(
        initialDraft: CreateActivityDraft? = nil,
        templateStore: ActivityCreateTemplateStore = ActivityCreateTemplateStore()
    ) -> CreateActivityViewModel {
        let viewModel = CreateActivityViewModel(
            createActivity: CreateActivityUseCase(repository: feedRepository),
            templateStore: templateStore
        )
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

    public func fetchActivityShareContext(activityID: String) async -> ActivityShareContext? {
        guard let detail = try? await feedRepository.fetchActivity(id: activityID) else { return nil }
        return ActivityShareContext(
            activityID: detail.id,
            title: detail.title,
            scheduleLine: detail.scheduleLine,
            mediaGallery: ActivityShareContext.mockMediaGallery(activityID: detail.id)
        )
    }

    public func syncReminders(for detail: ActivityDetail) async {
        await ActivityLocalReminderScheduler.syncReminders(for: detail)
    }
}
