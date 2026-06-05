// Module: SparkDesignSystem — HIG-aligned adaptive layout constants (iPhone / iPad).

import SwiftUI

/// Shared breakpoints for split navigation and readable content width on regular size class.
public enum SparkAdaptiveLayout {
    public static let sidebarIdealWidth: CGFloat = 320
    public static let contentReadableMaxWidth: CGFloat = 640
    public static let discoverCardMaxWidth: CGFloat = 480

    /// HIG: use `NavigationSplitView` when horizontal size class is regular (iPad landscape / regular width).
    public static func usesSplit(horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }
}

extension View {
    /// Centers content and caps line length on wide screens (HIG readability).
    public func sparkReadableWidth(_ maxWidth: CGFloat = SparkAdaptiveLayout.contentReadableMaxWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
