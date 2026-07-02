// Module: SparkActivity — Tab chrome sync (top filter + bottom CTA).

import SwiftUI

extension ActivityRootView {
    var isAtActivityHomeRoot: Bool {
        !showMyActivities && navigationPath.isEmpty
    }

    func syncTabChrome() {
        tabChrome.navigation.isAtHomeRoot = isAtActivityHomeRoot
        tabChrome.navigation.isHomeObscured = showMyActivities
        tabChrome.navigation.isDiscoverSegmentActive = selectedHomeSegment == .discover
        tabChrome.navigation.hasBrowseCatalog = coordinator.hasBrowseCatalog
        tabChrome.navigation.isGuest = !isAuthenticated

        if isAtActivityHomeRoot || showMyActivities {
            tabChrome.clearDetailAccessory()
        }
        tabChrome.reconcile()
    }

    func reloadVisibleCatalogs() async {
        await viewModel.load()
        if let browseViewModel {
            await browseViewModel.reload()
        }
    }
}
