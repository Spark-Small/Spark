//
//  PublishActivityUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct PublishActivityUseCase: Sendable {
    public init() {}

    public func execute(
        draft: PublishActivityDraft,
        activities: inout [Activity],
        joinedIDs: inout Set<UUID>,
        activityID: UUID = UUID()
    ) -> Result<UUID, PublishActivityFailure> {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedLocation.isEmpty, !trimmedSummary.isEmpty else {
            return .failure(.invalidFields)
        }
        guard !draft.category.isBrowseAggregate else {
            return .failure(.browseAggregateCategory)
        }

        let trimmedFee = draft.fee.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedFee = trimmedFee.isEmpty ? draft.freeFeeLabel : trimmedFee
        var participantUserIDs: [UUID] = []
        if let hostUserID = draft.hostUserID {
            participantUserIDs = [hostUserID]
        }

        activities.insert(
            Activity(
                id: activityID,
                title: trimmedTitle,
                category: draft.category,
                location: trimmedLocation,
                date: draft.date,
                capacity: max(draft.capacity, 2),
                joined: 1,
                hostName: draft.hostName,
                summary: trimmedSummary,
                fee: resolvedFee,
                tags: draft.tags,
                distanceKM: draft.distanceKM,
                localCoverName: draft.localCoverName,
                participantNames: [draft.hostName],
                latitude: draft.latitude,
                longitude: draft.longitude,
                hostUserID: draft.hostUserID,
                participantUserIDs: participantUserIDs
            ),
            at: 0
        )
        joinedIDs.insert(activityID)
        return .success(activityID)
    }
}
