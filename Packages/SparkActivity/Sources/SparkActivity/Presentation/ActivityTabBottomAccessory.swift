// Module: SparkActivity — Tab bar bottom accessory (discover create / detail RSVP).

import SparkDesignSystem
import SwiftUI

/// Context-aware primary action docked above the tab bar on the Activity tab (iOS 26+).
@available(iOS 26.1, *)
public struct ActivityTabBottomAccessory: View {
    @Bindable private var chrome: ActivityTabChrome
    private let fallback: @MainActor () -> Void

    public init(
        chrome: ActivityTabChrome,
        fallback: @escaping @MainActor () -> Void
    ) {
        self._chrome = Bindable(chrome)
        self.fallback = fallback
    }

    public var body: some View {
        SparkTabBottomAccessory(
            title: chrome.kind.title,
            systemImage: chrome.kind.systemImage,
            accessibilityHint: chrome.kind.accessibilityHint,
            isInteractionEnabled: chrome.kind.isInteractionEnabled,
            isLoading: chrome.isLoading
        ) {
            chrome.performPrimaryAction(fallback: fallback)
        }
        .id(chrome.kind)
    }
}
