// Module: SparkActivity — Host edits an existing activity.

import Foundation
import Observation

@MainActor
@Observable
public final class EditActivityViewModel {
    public enum SubmitState: Equatable, Sendable {
        case idle
        case submitting
        case failure(String)
    }

    public var draft: CreateActivityDraft
    public private(set) var submitState: SubmitState = .idle

    private let activityID: String
    private let updateActivity: any UpdateActivityUseCaseProtocol

    public init(activity: ActivityDetail, updateActivity: any UpdateActivityUseCaseProtocol) {
        activityID = activity.id
        draft = CreateActivityDraft(
            title: activity.title,
            description: activity.description,
            locationName: activity.locationName,
            startsAt: activity.startsAt,
            capacity: activity.capacity
        )
        self.updateActivity = updateActivity
    }

    public convenience init(activity: ActivityDetail, repository: any ActivityFeedRepository) {
        self.init(activity: activity, updateActivity: UpdateActivityUseCase(repository: repository))
    }

    public func submit() async -> ActivityDetail? {
        guard draft.isValid else { return nil }
        submitState = .submitting
        do {
            let detail = try await updateActivity(activityID: activityID, draft: draft)
            submitState = .idle
            return detail
        } catch is CancellationError {
            submitState = .idle
            return nil
        } catch let error as ActivityError {
            submitState = .failure(error.errorDescription ?? error.localizedDescription)
            return nil
        } catch {
            submitState = .failure(error.localizedDescription)
            return nil
        }
    }
}
