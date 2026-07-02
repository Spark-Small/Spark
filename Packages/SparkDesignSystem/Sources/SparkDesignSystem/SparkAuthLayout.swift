// Module: SparkDesignSystem — Login / sign-in layout tokens (HIG 44pt+ targets).

import SwiftUI

/// Shared spacing and sizing for authentication screens.
public enum SparkAuthLayout {
    /// HIG minimum touch target with comfortable vertical padding for labels.
    public static let signInButtonMinHeight: CGFloat = 52
    public static let signInButtonCornerRadius: CGFloat = 20
    public static let signInButtonSpacing: CGFloat = 12
    public static let sectionSpacing: CGFloat = 24
    public static let screenHorizontalPadding: CGFloat = 24
    /// Circular social sign-in control (HIG 44pt minimum).
    public static let socialButtonSize: CGFloat = 44
    /// Even spacing for bottom social bar (tab-bar-adjacent).
    public static let socialBarHorizontalPadding: CGFloat = 32
    /// Scroll bottom inset so content clears the bottom social toolbar.
    public static let socialBarReservedHeight: CGFloat = 72
    /// Form row insets for full-width auth action buttons (login / Apple).
    public static let authActionRowInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
    /// Legal consent row insets below sign-in actions.
    public static let legalRowInsets = EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16)
}
