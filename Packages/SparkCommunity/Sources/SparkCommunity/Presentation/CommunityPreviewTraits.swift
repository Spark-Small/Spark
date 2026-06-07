// Module: SparkCommunity — Shared Preview matrix (Light / Dark / Accessibility XL).

import SwiftUI

enum CommunityPreviewTraits {
    static func matrix<V: View>(
        _ name: String,
        @ViewBuilder content: @escaping () -> V
    ) -> some View {
        Group {
            content()
                .previewDisplayName("\(name) — Light")
            content()
                .preferredColorScheme(.dark)
                .previewDisplayName("\(name) — Dark")
            content()
                .dynamicTypeSize(.accessibility3)
                .previewDisplayName("\(name) — XL")
        }
    }
}
