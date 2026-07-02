// Module: SparkCommunity — Community tab bottom accessory coordination.

import Foundation
import Observation

/// Coordinates the Community tab bottom accessory between feed list and `TabView`.
@MainActor
@Observable
public final class CommunityTabChrome {
    public private(set) var kind: CommunityTabBottomAccessoryKind = .hidden
    public private(set) var isLoading = false

  public var actionHandler: (@MainActor () -> Void)?

    public init() {}

    public var isBottomAccessoryEnabled: Bool {
        kind.isVisible
    }

    public func clearAccessory() {
        kind = .hidden
        isLoading = false
        actionHandler = nil
    }

    /// Feed list at root: compose-post CTA (guest vs signed-in copy).
    public func syncFeedCompose(
        isFeedActive: Bool,
        guest: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        guard isFeedActive else {
            clearAccessory()
            return
        }
        kind = .composePost(guest: guest)
        isLoading = false
        actionHandler = action
    }

    public func sync(tabSelected: Bool) {
        if !tabSelected {
            clearAccessory()
        }
    }
}
