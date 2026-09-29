//
//  CredentialArtTheme.swift
//  坐标系
//
//  彩绘主题色（单套 SVG 模板 + 运行时 ACCENT_* 替换）。
//

import SwiftUI

enum CredentialArtScene: String, CaseIterable, Hashable {
    case transit
    case event
    case dining
    case workshop
    case generic
    case memento

    var resourceName: String { rawValue }

    var fallbackAssetName: String {
        switch self {
        case .transit: "CredentialArtTransit"
        case .event: "CredentialArtEvent"
        case .dining: "CredentialArtDining"
        case .workshop: "CredentialArtWorkshop"
        case .generic: "CredentialArtGeneric"
        case .memento: "CredentialArtMemento"
        }
    }
}

struct CredentialArtTheme: Hashable {
    let accentHex: String
    let accentMutedHex: String
    let surface: Color

    static let transit = CredentialArtTheme(
        accentHex: "#5B8DEF",
        accentMutedHex: "#A8C5F7",
        surface: Color(red: 237 / 255, green: 244 / 255, blue: 250 / 255)
    )

    static let event = CredentialArtTheme(
        accentHex: "#8B6CCF",
        accentMutedHex: "#C9B8E8",
        surface: Color(red: 242 / 255, green: 238 / 255, blue: 250 / 255)
    )

    static let dining = CredentialArtTheme(
        accentHex: "#E8925C",
        accentMutedHex: "#F2C4A0",
        surface: Color(red: 250 / 255, green: 242 / 255, blue: 236 / 255)
    )

    static let workshop = CredentialArtTheme(
        accentHex: "#D46B8A",
        accentMutedHex: "#E8A8BC",
        surface: Color(red: 248 / 255, green: 240 / 255, blue: 242 / 255)
    )

    static let generic = CredentialArtTheme(
        accentHex: "#5B8DEF",
        accentMutedHex: "#A8C5F7",
        surface: Color(red: 245 / 255, green: 245 / 255, blue: 247 / 255)
    )

    static func forScene(_ scene: CredentialArtScene) -> CredentialArtTheme {
        switch scene {
        case .transit: .transit
        case .event: .event
        case .dining: .dining
        case .workshop: .workshop
        case .generic, .memento: .generic
        }
    }
}
