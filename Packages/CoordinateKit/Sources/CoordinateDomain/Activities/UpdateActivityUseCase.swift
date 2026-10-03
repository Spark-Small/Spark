//
//  UpdateActivityUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct UpdateActivityUseCase: Sendable {
    public init() {}

    public func execute(
        draft: UpdateActivityDraft,
        activities: inout [Activity],
        hostName: String,
        hostUserID: UUID?
    ) -> Result<Void, UpdateActivityFailure> {
        guard let index = activities.firstIndex(where: { $0.id == draft.id }) else {
            return .failure(.activityNotFound)
        }
        guard ActivityHostAuthorization.isHost(
            activities[index],
            hostName: hostName,
            hostUserID: hostUserID
        ) else {
            return .failure(.notHost)
        }

        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedLocation.isEmpty, !trimmedSummary.isEmpty else {
            return .failure(.invalidFields)
        }
        guard !draft.category.isBrowseAggregate else {
            return .failure(.browseAggregateCategory)
        }

        let joinedCount = activities[index].joined
        let trimmedFee = draft.fee.trimmingCharacters(in: .whitespacesAndNewlines)
        activities[index].title = trimmedTitle
        activities[index].category = draft.category
        activities[index].location = trimmedLocation
        activities[index].date = draft.date
        activities[index].capacity = max(draft.capacity, max(joinedCount, 2))
        activities[index].summary = trimmedSummary
        activities[index].fee = trimmedFee.isEmpty ? draft.freeFeeLabel : trimmedFee
        activities[index].tags = draft.tags
        if let localCoverName = draft.localCoverName {
            activities[index].localCoverName = localCoverName
        }
        if draft.latitude != nil {
            activities[index].latitude = draft.latitude
        }
        if draft.longitude != nil {
            activities[index].longitude = draft.longitude
        }
        if let distanceKM = draft.distanceKM {
            activities[index].distanceKM = distanceKM
        }
        return .success(())
    }
}
