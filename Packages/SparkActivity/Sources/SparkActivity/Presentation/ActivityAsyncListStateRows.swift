// Module: SparkActivity — Shared async list rows (loading / error) for activity feeds.

import SparkDesignSystem
import SwiftUI

struct ActivityAsyncListLoadingRow: View {
    let accessibilityLabel: String

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, minHeight: 320)
            .sparkLoadingAccessibilityLabel(accessibilityLabel)
            .sparkFlatTabListRow()
    }
}

struct ActivityAsyncListErrorRow: View {
    let title: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        SparkRetryUnavailableView(
            title: title,
            description: message
        ) {
            onRetry()
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .sparkFlatTabListRow()
    }
}
