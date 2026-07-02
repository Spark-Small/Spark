// Module: SparkCommunity — Tab bottom accessory sync (feed compose).

import SparkCore
import SparkPayments
import SwiftUI

extension CommunityRootView {
    var isAtCommunityHomeRoot: Bool {
        navigationPath.isEmpty
    }

    func syncTabChrome() {
        guard SparkFeatureFlags.isCommunityPostingEnabled else {
            tabChrome.clearAccessory()
            return
        }

        guard isAtCommunityHomeRoot else {
            tabChrome.clearAccessory()
            return
        }

        let isFeedActive = selectedSegment == .feed
        tabChrome.syncFeedCompose(isFeedActive: isFeedActive, guest: !isAuthenticated) {
            presentComposePost()
        }
    }
}
