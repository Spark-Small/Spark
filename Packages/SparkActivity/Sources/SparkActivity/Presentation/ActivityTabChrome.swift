// Module: SparkActivity — Activity tab chrome (top filter + bottom CTA accessories).

import Foundation
import Observation

/// Navigation inputs for tab accessories (written by `ActivityRootView` / shell).
public struct ActivityTabChromeNavigationState: Equatable, Sendable {
    public var isActivityTabSelected = true
    public var isAtHomeRoot = true
    public var isHomeObscured = false
    public var isDiscoverSegmentActive = true
    public var hasBrowseCatalog = false
    public var isGuest = false

    public init() {}
}

/// Detail RSVP inputs (written by `ActivityDetailView`; cleared by root when leaving detail).
public struct ActivityTabChromeDetailState: Equatable, Sendable {
    public var isActive = false
    public var canChangeRSVP = false
    public var rsvpStatus: ActivityRSVPStatus = .invited
    public var canSelectGoing = false
    public var isLoading = false

    public init() {}
}

/// Single coordinator for Activity tab accessories — screens write inputs, `reconcile()` owns output.
@MainActor
@Observable
public final class ActivityTabChrome {
    public var navigation = ActivityTabChromeNavigationState()
    public var detail = ActivityTabChromeDetailState()

    public private(set) var kind: ActivityTabBottomAccessoryKind = .hidden
    public private(set) var showsDiscoverTopFilter = false
    public private(set) var isLoading = false

    /// Primary action for detail RSVP / sign-in; list create uses shell `onCreateActivity` when nil.
    public var actionHandler: (@MainActor () -> Void)?

    package var detailSignInHandler: (@MainActor () -> Void)?
    package var detailRSVPHandler: (@MainActor () -> Void)?

    public init() {}

    public var isBottomAccessoryEnabled: Bool {
        kind.isVisible
    }

    public var isTopAccessoryEnabled: Bool {
        showsDiscoverTopFilter
    }

    /// Invokes the resolved primary action at tap time (handlers are not snapshotted in accessory views).
    public func performPrimaryAction(fallback: @MainActor () -> Void) {
        switch kind {
        case .signInToRSVP:
            detailSignInHandler?()
        case .rsvpGoing:
            detailRSVPHandler?()
        case .createActivity:
            fallback()
        case .hidden:
            break
        }
    }

    public func registerDetailHandlers(
        signIn: (@MainActor () -> Void)?,
        submitGoing: (@MainActor () -> Void)?
    ) {
        detailSignInHandler = signIn
        detailRSVPHandler = submitGoing
    }

    public func clearDetailAccessory() {
        detail = ActivityTabChromeDetailState()
        detailSignInHandler = nil
        detailRSVPHandler = nil
    }

    /// Resolves bottom + top accessory state from navigation + detail inputs.
    public func reconcile() {
        showsDiscoverTopFilter = canShowDiscoverTopFilter

        guard navigation.isActivityTabSelected else {
            applyHidden()
            return
        }

        if detail.isActive, detail.canChangeRSVP, detail.rsvpStatus == .invited {
            if navigation.isGuest {
                apply(
                    kind: .signInToRSVP,
                    isLoading: false,
                    handler: detailSignInHandler
                )
            } else {
                apply(
                    kind: .rsvpGoing(isEnabled: detail.canSelectGoing),
                    isLoading: detail.isLoading,
                    handler: detailRSVPHandler
                )
            }
            return
        }

        guard canShowDiscoverHomeChrome else {
            applyHidden()
            return
        }

        apply(
            kind: .createActivity(guest: navigation.isGuest),
            isLoading: false,
            handler: nil
        )
    }

    private var canShowDiscoverHomeChrome: Bool {
        navigation.isAtHomeRoot
            && !navigation.isHomeObscured
            && navigation.isDiscoverSegmentActive
            && navigation.hasBrowseCatalog
    }

    private var canShowDiscoverTopFilter: Bool {
        navigation.isActivityTabSelected
            && canShowDiscoverHomeChrome
            && !detail.isActive
    }

    private func applyHidden() {
        apply(kind: .hidden, isLoading: false, handler: nil)
    }

    private func apply(
        kind: ActivityTabBottomAccessoryKind,
        isLoading: Bool,
        handler: (@MainActor () -> Void)?
    ) {
        self.kind = kind
        self.isLoading = isLoading
        actionHandler = handler
    }
}
