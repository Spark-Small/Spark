// Module: SparkBuddy — Provider application form state.

import Foundation
import OSLog
import SparkCore

@MainActor
@Observable
public final class BuddyProviderApplicationViewModel {
    enum SubmitState: Equatable {
        case idle
        case submitting
        case success(BuddyProviderStatus)
        case failure(String)
    }

    var displayName = ""
    var city = ""
    var serviceCategory: BuddyServiceCategory = .cityWalk
    var bio = ""
    var selectedTags: [String] = []
    private(set) var submitState: SubmitState = .idle

    let suggestedTags = [
        String(localized: "buddy.mock.tag.cityWalk", defaultValue: "CityWalk达人", comment: "Tag"),
        String(localized: "buddy.mock.tag.food", defaultValue: "美食达人", comment: "Tag"),
        String(localized: "buddy.mock.tag.photoPro", defaultValue: "摄影达人", comment: "Tag"),
        String(localized: "buddy.mock.tag.night", defaultValue: "夜景达人", comment: "Tag")
    ]

    private let submitApplication: any SubmitBuddyProviderApplicationUseCaseProtocol
    private let logger = SparkLog.logger(category: "BuddyProviderApply")

    public init(submitApplication: any SubmitBuddyProviderApplicationUseCaseProtocol) {
        self.submitApplication = submitApplication
    }

    var canSubmit: Bool {
        BuddyProviderApplicationDraft(
            displayName: displayName,
            city: city,
            serviceCategory: serviceCategory,
            bio: bio,
            capabilityTags: selectedTags
        ).isValid
    }

    var errorMessage: String? {
        if case .failure(let message) = submitState { return message }
        return nil
    }

    var isSubmitting: Bool {
        if case .submitting = submitState { return true }
        return false
    }

    var didSucceed: Bool {
        if case .success = submitState { return true }
        return false
    }

    func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    func submit() async {
        let draft = BuddyProviderApplicationDraft(
            displayName: displayName,
            city: city,
            serviceCategory: serviceCategory,
            bio: bio,
            capabilityTags: selectedTags
        )
        guard draft.isValid else {
            submitState = .failure(
                String(
                    localized: "buddy.provider.form.invalid",
                    defaultValue: "请完善资料并选择至少一个能力标签",
                    comment: "Invalid form"
                )
            )
            return
        }
        submitState = .submitting
        do {
            let status = try await submitApplication(draft: draft)
            BuddyTelemetry.providerApplicationSubmitted(category: draft.serviceCategory.rawValue)
            submitState = .success(status)
        } catch is CancellationError {
            submitState = .idle
        } catch {
            logger.error("Provider application failed: \(error.localizedDescription, privacy: .public)")
            submitState = .failure(AppError(buddyUnderlying: error).localizedDescription)
        }
    }
}
