// Module: SparkDesignSystem — Photo overlay scrim for text legibility (not glass).

import SwiftUI

public enum SparkPhotoTextScrimStyle: Sendable {
    /// Dark cover band — white text; dark gradient scrim.
    case darkBackground
    /// Light cover band — dark text; minimal light scrim.
    case lightBackground
    /// Before cover analysis completes — semantic text with neutral scrim.
    case unknown
}

extension View {
    /// Bottom gradient scrim for readable text over photos. Not a glass surface.
    public func sparkPhotoTextScrim(style: SparkPhotoTextScrimStyle = .unknown) -> some View {
        background {
            switch style {
            case .darkBackground:
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.55)
            case .lightBackground:
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.28)
            case .unknown:
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.35)
            }
        }
    }
}
