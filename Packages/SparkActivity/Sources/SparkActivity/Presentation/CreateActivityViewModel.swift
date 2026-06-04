// Module: SparkActivity — Create activity form state.

import Foundation
import Observation

@MainActor
@Observable
public final class CreateActivityViewModel {
    public enum SubmitState: Equatable, Sendable {
        case idle
        case submitting
        case failure(String)
    }

    public var draft = CreateActivityDraft()
    public private(set) var submitState: SubmitState = .idle

    private let createActivity: CreateActivityUseCase

    public init(repository: any ActivityFeedRepository) {
        createActivity = CreateActivityUseCase(repository: repository)
    }

    public func submit() async -> ActivityDetail? {
        guard draft.isValid else { return nil }
        submitState = .submitting
        do {
            let detail = try await createActivity(draft: draft)
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
