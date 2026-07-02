// Module: SparkBuddy — Browse toolbar (trailing options menu).

import SparkDesignSystem
import SwiftUI

extension BuddyRootView {
    var buddyBrowseOptionsButton: some View {
        Button {
            BuddyTelemetry.browseOptionsOpened(
                hasActiveFilters: viewModel.browseOptions.hasActiveSecondaryFilters
            )
            showBrowseOptions = true
        } label: {
            Image(systemName: "ellipsis")
                .imageScale(.medium)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            String(
                localized: "buddy.options.toolbar.a11y",
                defaultValue: "筛选选项",
                comment: "Buddy browse options button"
            )
        )
        .accessibilityHint(
            String(
                localized: "buddy.options.toolbar.hint",
                defaultValue: "计费方式、排序与认证筛选",
                comment: "Buddy browse options hint"
            )
        )
    }
}
