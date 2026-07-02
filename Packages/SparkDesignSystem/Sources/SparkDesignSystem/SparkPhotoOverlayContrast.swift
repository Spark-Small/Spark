// Module: SparkDesignSystem — Photo overlay contrast tokens (algorithm + foreground/scrim).

import SwiftUI
import UIKit

public enum SparkPhotoOverlayTextRole: Sendable {
    case primary
    case secondary
}

/// Resolved scrim + foreground colors for text over a photo band.
public struct SparkPhotoOverlayContrast: Sendable, Equatable {
    public enum Resolution: Sendable, Equatable {
        case unknown
        case lightBackground
        case darkBackground
    }

    public let resolution: Resolution

    public static let unknown = SparkPhotoOverlayContrast(resolution: .unknown)

    public init(resolution: Resolution) {
        self.resolution = resolution
    }

    /// Samples the bottom band of a cover image and returns paired scrim + text tokens.
    public static func analyze(
        image: UIImage,
        bottomBandFraction: CGFloat = 0.35,
        lightThreshold: CGFloat = 0.55
    ) -> SparkPhotoOverlayContrast {
        let isLight = SparkImageLuminance.isLightBackground(
            in: image,
            bottomBandFraction: bottomBandFraction,
            lightThreshold: lightThreshold
        )
        return SparkPhotoOverlayContrast(
            resolution: isLight ? .lightBackground : .darkBackground
        )
    }

    public var scrimStyle: SparkPhotoTextScrimStyle {
        switch resolution {
        case .unknown: .unknown
        case .lightBackground: .lightBackground
        case .darkBackground: .darkBackground
        }
    }

    public func foregroundColor(for role: SparkPhotoOverlayTextRole) -> Color {
        switch resolution {
        case .unknown:
            switch role {
            case .primary: .primary
            case .secondary: .secondary
            }
        case .lightBackground:
            switch role {
            case .primary: .black
            case .secondary: Color.black.opacity(0.68)
            }
        case .darkBackground:
            switch role {
            case .primary: .white
            case .secondary: Color.white.opacity(0.78)
            }
        }
    }
}

extension View {
    /// Bottom gradient scrim driven by analyzed photo contrast.
    public func sparkPhotoTextScrim(contrast: SparkPhotoOverlayContrast) -> some View {
        sparkPhotoTextScrim(style: contrast.scrimStyle)
    }
}
