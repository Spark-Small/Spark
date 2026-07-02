// Module: SparkActivity — Activity detail tab chrome + RSVP fallback layout.

import SparkDesignSystem
import SwiftUI

extension ActivityDetailView {
    func refreshTabAccessory() {
        guard let tabChrome else { return }

        guard let activity = viewModel.activity,
              activity.canChangeRSVP,
              activity.rsvpStatus == .invited
        else {
            tabChrome.clearDetailAccessory()
            tabChrome.reconcile()
            return
        }

        tabChrome.detail.isActive = true
        tabChrome.detail.canChangeRSVP = activity.canChangeRSVP
        tabChrome.detail.rsvpStatus = activity.rsvpStatus
        tabChrome.detail.canSelectGoing = activity.canSelectGoing
        tabChrome.detail.isLoading = viewModel.isUpdatingRSVP

        if isAuthenticated {
            tabChrome.registerDetailHandlers(
                signIn: nil,
                submitGoing: {
                    Task { @MainActor in
                        await viewModel.submitRSVP(.going)
                    }
                }
            )
        } else {
            tabChrome.registerDetailHandlers(
                signIn: { [onSignInRequired] in
                    onSignInRequired?()
                },
                submitGoing: nil
            )
        }
        tabChrome.reconcile()
    }

    var detailRSVPFallbackKind: ActivityTabBottomAccessoryKind {
        if !isAuthenticated {
            return .signInToRSVP
        }
        guard let activity = viewModel.activity else { return .hidden }
        return .rsvpGoing(isEnabled: activity.canSelectGoing)
    }

    var showsDetailRSVPFallback: Bool {
        guard let activity = viewModel.activity,
              activity.canChangeRSVP,
              activity.rsvpStatus == .invited
        else { return false }

        if let tabChrome, isActivityTabSelected {
            if #available(iOS 26.1, *) {
                return false
            }
            return true
        }
        return tabChrome == nil
    }

    var detailBottomScrollInset: CGFloat {
        guard showsDetailRSVPFallback || tabAccessoryBottomInset > 0 else { return 0 }
        if showsDetailRSVPFallback {
            return SparkLayoutMetrics.tabBottomAccessoryScrollInset
        }
        return tabAccessoryBottomInset
    }

    var tabAccessoryBottomInset: CGFloat {
        guard tabChrome != nil,
              let activity = viewModel.activity,
              activity.canChangeRSVP,
              activity.rsvpStatus == .invited
        else { return 0 }
        return SparkLayoutMetrics.tabBottomAccessoryScrollInset
    }
}
