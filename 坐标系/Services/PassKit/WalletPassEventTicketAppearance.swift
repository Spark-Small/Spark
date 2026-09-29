//
//  WalletPassEventTicketAppearance.swift
//  坐标系
//
//  PassKit eventTicket 官方三色 + strip 分层（Pass Design and Creation）。
//

import SwiftUI
import UIKit
import CoordinateModels

enum WalletPassEventTicketAppearance {
    static let foregroundRGB = "rgb(255, 255, 255)"
    static let labelRGB = "rgb(174, 174, 178)"

    static var foregroundColor: Color { .white }

    static var labelColor: Color {
        Color(red: 174 / 255, green: 174 / 255, blue: 178 / 255)
    }

    static func backgroundRGB(for category: ActivityCategory) -> String {
        let rgb = backgroundComponents(for: category)
        return PassTemplateResources.rgbString(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    static func backgroundColor(for category: ActivityCategory) -> Color {
        color(from: backgroundComponents(for: category))
    }

    static func uiBackgroundColor(for category: ActivityCategory) -> UIColor {
        uiColor(from: backgroundComponents(for: category))
    }

    static func stripSurfaceColor(for category: ActivityCategory) -> Color {
        color(from: stripSurfaceComponents(for: category))
    }

    static func uiStripSurfaceColor(for category: ActivityCategory) -> UIColor {
        uiColor(from: stripSurfaceComponents(for: category))
    }

    // MARK: - Palette

    private typealias RGBComponents = (red: Int, green: Int, blue: Int)

    private static func backgroundComponents(for category: ActivityCategory) -> RGBComponents {
        switch category {
        case .outdoorSports: (31, 56, 82)
        case .cityExplore: (26, 58, 64)
        case .food: (71, 51, 41)
        case .interestSocial: (45, 38, 68)
        case .entertainment: (62, 32, 52)
        case .handmade: (64, 42, 50)
        case .learning: (32, 52, 72)
        case .all, .forYou: (28, 28, 31)
        }
    }

    private static func stripSurfaceComponents(for category: ActivityCategory) -> RGBComponents {
        switch category {
        case .outdoorSports, .cityExplore: (237, 244, 250)
        case .food: (250, 242, 236)
        case .interestSocial: (242, 238, 250)
        case .entertainment: (248, 236, 242)
        case .handmade: (248, 240, 242)
        case .learning: (236, 242, 250)
        case .all, .forYou: (245, 245, 247)
        }
    }

    private static func color(from rgb: RGBComponents) -> Color {
        Color(
            red: Double(rgb.red) / 255,
            green: Double(rgb.green) / 255,
            blue: Double(rgb.blue) / 255
        )
    }

    private static func uiColor(from rgb: RGBComponents) -> UIColor {
        UIColor(
            red: CGFloat(rgb.red) / 255,
            green: CGFloat(rgb.green) / 255,
            blue: CGFloat(rgb.blue) / 255,
            alpha: 1
        )
    }
}
