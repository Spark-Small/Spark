// Module: SparkDesignSystem — Photo overlay scrim for text legibility (not glass).

import SwiftUI

extension View {
    /// Bottom gradient scrim for readable text over photos. Not a glass surface.
    public func sparkPhotoTextScrim() -> some View {
        background {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.55)
        }
    }
}
