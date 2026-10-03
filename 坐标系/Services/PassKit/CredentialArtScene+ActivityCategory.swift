//
//  CredentialArtScene+ActivityCategory.swift
//  坐标系
//
//  活动分类 → CredentialArt 场景（Design 层不依赖 CoordinateModels）。
//

import CoordinateModels

extension CredentialArtScene {
    static func forActivityCategory(_ category: ActivityCategory) -> CredentialArtScene {
        switch category {
        case .outdoorSports, .cityExplore: .transit
        case .entertainment, .interestSocial: .event
        case .food: .dining
        case .handmade, .learning: .workshop
        case .all, .forYou: .generic
        }
    }
}
