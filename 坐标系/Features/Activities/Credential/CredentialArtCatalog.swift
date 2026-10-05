//
//  CredentialArtCatalog.swift
//  坐标系
//
//  票种 × 呈现态 → CredentialArt 场景与主题。
//

import Foundation
import CoordinateModels

enum CredentialArtCatalog {
    static func resolve(
        kind: ActivityJourneyPassKind,
        presentation: ActivityJourneyCredentialPresentationMode
    ) -> (scene: CredentialArtScene, theme: CredentialArtTheme) {
        let scene = scene(kind: kind, presentation: presentation)
        return (scene, CredentialArtTheme.forScene(baseScene(for: kind)))
    }

    static func resolveForShare(
        kind: ActivityJourneyPassKind,
        isPostEvent: Bool
    ) -> (scene: CredentialArtScene, theme: CredentialArtTheme) {
        let scene: CredentialArtScene = isPostEvent
            ? .memento
            : baseScene(for: kind)
        return (scene, CredentialArtTheme.forScene(baseScene(for: kind)))
    }

    static func baseScene(for kind: ActivityJourneyPassKind) -> CredentialArtScene {
        switch kind {
        case .transit: .transit
        case .event: .event
        case .dining: .dining
        case .workshop: .workshop
        case .generic: .generic
        }
    }

    private static func scene(
        kind: ActivityJourneyPassKind,
        presentation: ActivityJourneyCredentialPresentationMode
    ) -> CredentialArtScene {
        switch presentation {
        case .memento:
            return .memento
        case .fulfillment, .voided:
            return baseScene(for: kind)
        }
    }
}
