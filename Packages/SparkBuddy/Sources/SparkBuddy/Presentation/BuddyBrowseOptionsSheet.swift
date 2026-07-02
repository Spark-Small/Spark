// Module: SparkBuddy — Leading toolbar options: billing + secondary filters.

import SparkDesignSystem
import SwiftUI

struct BuddyBrowseOptionsSheet: View {
    @Bindable var viewModel: BuddyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        String(
                            localized: "buddy.options.billing",
                            defaultValue: "计费方式",
                            comment: "Billing filter section"
                        ),
                        selection: $viewModel.browseOptions.billingFilter
                    ) {
                        ForEach(BuddyBillingFilter.allCases) { filter in
                            Text(filter.localizedTitle).tag(filter)
                        }
                    }
                } header: {
                    Text(
                        String(
                            localized: "buddy.options.billing.section",
                            defaultValue: "价格与计费",
                            comment: "Billing section header"
                        )
                    )
                }

                Section {
                    Picker(
                        String(
                            localized: "buddy.options.sort",
                            defaultValue: "排序",
                            comment: "Sort order picker"
                        ),
                        selection: $viewModel.browseOptions.sortOrder
                    ) {
                        ForEach(BuddyBrowseSortOrder.allCases) { order in
                            Text(order.localizedTitle).tag(order)
                        }
                    }
                    Toggle(
                        String(
                            localized: "buddy.options.verifiedOnly",
                            defaultValue: "仅看真人认证陪玩",
                            comment: "Verified only toggle"
                        ),
                        isOn: $viewModel.browseOptions.verifiedOnly
                    )
                } header: {
                    Text(
                        String(
                            localized: "buddy.options.display.section",
                            defaultValue: "展示条件",
                            comment: "Display filters section"
                        )
                    )
                }

                if viewModel.browseOptions.hasActiveSecondaryFilters {
                    Section {
                        Button(
                            String(
                                localized: "buddy.options.reset",
                                defaultValue: "恢复默认筛选",
                                comment: "Reset browse options"
                            )
                        ) {
                            viewModel.resetBrowseOptions()
                        }
                    }
                }
            }
            .navigationTitle(
                String(
                    localized: "buddy.options.title",
                    defaultValue: "筛选选项",
                    comment: "Browse options sheet title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done", defaultValue: "完成", comment: "Done")) {
                        dismiss()
                    }
                }
            }
            .sparkPhoneStyleNavigationBar()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Buddy browse options") {
    BuddyBrowseOptionsSheet(viewModel: BuddyViewModel(repository: MockBuddyRepository()))
}
