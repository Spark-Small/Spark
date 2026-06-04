// Module: SparkDesignSystem — Error empty state with optional retry action.

import SwiftUI

/// System empty/error state with a single retry action when `onRetry` is provided.
public struct SparkRetryUnavailableView: View {
    let title: String
    let description: String
    let systemImage: String
    let onRetry: (() -> Void)?

    public init(
        title: String,
        description: String,
        systemImage: String = "exclamationmark.triangle",
        onRetry: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.onRetry = onRetry
    }

    public var body: some View {
        if let onRetry {
            ContentUnavailableView {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: systemImage)
                }
            } description: {
                Text(description)
            } actions: {
                Button(
                    String(localized: "common.retry", defaultValue: "重试", comment: "Retry failed load")
                ) {
                    onRetry()
                }
            }
        } else {
            ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
        }
    }
}
