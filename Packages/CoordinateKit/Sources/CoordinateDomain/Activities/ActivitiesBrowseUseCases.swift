//
//  ActivitiesBrowseUseCases.swift
//  CoordinateDomain
//

import Foundation

public struct ActivitiesBrowseUseCases: Sendable {
    public let filter: FilterActivitiesBrowseUseCase

    public init(filter: FilterActivitiesBrowseUseCase = FilterActivitiesBrowseUseCase()) {
        self.filter = filter
    }
}
