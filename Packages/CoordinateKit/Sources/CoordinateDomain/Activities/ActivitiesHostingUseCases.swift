//
//  ActivitiesHostingUseCases.swift
//  CoordinateDomain
//

import Foundation

public struct ActivitiesHostingUseCases: Sendable {
    public let publish: PublishActivityUseCase
    public let update: UpdateActivityUseCase
    public let cancel: CancelActivityUseCase
    public let updateCapacity: UpdateActivityCapacityUseCase
    public let reschedule: RescheduleActivityUseCase

    public init(
        publish: PublishActivityUseCase = PublishActivityUseCase(),
        update: UpdateActivityUseCase = UpdateActivityUseCase(),
        cancel: CancelActivityUseCase = CancelActivityUseCase(),
        updateCapacity: UpdateActivityCapacityUseCase = UpdateActivityCapacityUseCase(),
        reschedule: RescheduleActivityUseCase = RescheduleActivityUseCase()
    ) {
        self.publish = publish
        self.update = update
        self.cancel = cancel
        self.updateCapacity = updateCapacity
        self.reschedule = reschedule
    }
}
