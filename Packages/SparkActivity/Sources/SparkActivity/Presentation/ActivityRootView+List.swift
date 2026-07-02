// Module: SparkActivity — Activity tab list shell and inbox row wiring.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    var compactRoot: some View {
        NavigationStack(path: $navigationPath) {
            activityListShell
                .navigationDestination(for: String.self) { activityID in
                    activityDetailView(activityID: activityID)
                }
                .navigationDestination(item: $hostProfileRoute) { route in
                    ActivityHostProfileView(
                        route: route,
                        isAuthenticated: isAuthenticated,
                        onOpenMessages: onOpenHostMessages,
                        onSignInRequired: onSignInRequired
                    )
                }
        }
    }

    var activityListShell: some View {
        SparkScreenContainer(
            navigationTitle: "",
            titleDisplayMode: .inline,
            embedding: .none
        ) {
            homeSegmentRootContent
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                activityHomeSegmentToolbarPicker
            }
            ToolbarItem(placement: .topBarTrailing) {
                activityToolbarButton
            }
        }
        .sparkPhoneStyleNavigationBar()
    }

    @ViewBuilder
    func inboxListRows(
        listItems: [ActivityItem],
        listFilter: ActivityListFilter
    ) -> some View {
        actionItemsInset(listFilter)
        ForEach(listItems, id: \.id) { item in
            let index = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
            activityRow(for: item, at: index)
        }
    }
}
