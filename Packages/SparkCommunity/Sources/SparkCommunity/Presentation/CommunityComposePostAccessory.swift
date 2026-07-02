// Module: SparkCommunity — Tab bar bottom accessory: compose post on feed (iOS 26+).

import SparkDesignSystem
import SwiftUI

/// Context-aware compose action docked above the tab bar on Community feed.
@available(iOS 26.1, *)
public struct CommunityComposePostAccessory: View {
    private let kind: CommunityTabBottomAccessoryKind
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        kind: CommunityTabBottomAccessoryKind,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.kind = kind
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        SparkTabBottomAccessory(
            title: kind.title,
            systemImage: kind.systemImage,
            accessibilityHint: kind.accessibilityHint,
            isInteractionEnabled: kind.isInteractionEnabled,
            isLoading: isLoading,
            action: action
        )
    }
}
