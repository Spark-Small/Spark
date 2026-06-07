// Module: SparkActivity — UseCase protocols for ViewModel testability.

import Foundation

public protocol FetchActivityFeedUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> [ActivityItem]
}

public protocol FetchActivityDetailUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String) async throws -> ActivityDetail
}

public protocol UpdateActivityRSVPUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, status: ActivityRSVPStatus) async throws -> ActivityDetail
}

public protocol CancelActivityUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String) async throws -> ActivityDetail
}

public protocol ReportActivityUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, reason: ActivityReportReason) async throws -> ActivityReportResult
}

public protocol JoinActivityWaitlistUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String) async throws -> ActivityDetail
}

public protocol PromoteFromWaitlistUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, attendeeID: String) async throws -> ActivityDetail
}

public protocol ReviewAttendeeRSVPUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, attendeeID: String, approve: Bool) async throws -> ActivityDetail
}

public protocol SetAttendeeCoHostUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, attendeeID: String, isCoHost: Bool) async throws -> ActivityDetail
}

public protocol AnnounceActivityUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, message: String) async throws
}

public protocol SubmitHostFeedbackUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, feedback: ActivityHostFeedback) async throws
}

public protocol FetchActivitiesByHostUseCaseProtocol: Sendable {
    func callAsFunction(hostID: String, excludingActivityID: String?) async throws -> [ActivityItem]
}

public protocol FetchActivityBrowsePageUseCaseProtocol: Sendable {
    func callAsFunction(query: ActivityBrowseQuery) async throws -> ActivityBrowsePage
}

public protocol CreateActivityUseCaseProtocol: Sendable {
    func callAsFunction(draft: CreateActivityDraft) async throws -> ActivityDetail
}

public protocol UpdateActivityUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, draft: CreateActivityDraft) async throws -> ActivityDetail
}

extension FetchActivityFeedUseCase: FetchActivityFeedUseCaseProtocol {}
extension FetchActivityDetailUseCase: FetchActivityDetailUseCaseProtocol {}
extension UpdateActivityRSVPUseCase: UpdateActivityRSVPUseCaseProtocol {}
extension CancelActivityUseCase: CancelActivityUseCaseProtocol {}
extension ReportActivityUseCase: ReportActivityUseCaseProtocol {}
extension JoinActivityWaitlistUseCase: JoinActivityWaitlistUseCaseProtocol {}
extension PromoteFromWaitlistUseCase: PromoteFromWaitlistUseCaseProtocol {}
extension ReviewAttendeeRSVPUseCase: ReviewAttendeeRSVPUseCaseProtocol {}
extension SetAttendeeCoHostUseCase: SetAttendeeCoHostUseCaseProtocol {}
extension AnnounceActivityUseCase: AnnounceActivityUseCaseProtocol {}
extension SubmitHostFeedbackUseCase: SubmitHostFeedbackUseCaseProtocol {}
extension FetchActivitiesByHostUseCase: FetchActivitiesByHostUseCaseProtocol {}
extension FetchActivityBrowsePageUseCase: FetchActivityBrowsePageUseCaseProtocol {}
extension CreateActivityUseCase: CreateActivityUseCaseProtocol {}
extension UpdateActivityUseCase: UpdateActivityUseCaseProtocol {}
