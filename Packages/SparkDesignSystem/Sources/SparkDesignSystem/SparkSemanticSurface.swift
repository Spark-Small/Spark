// Module: SparkDesignSystem — Semantic canvas + elevated module surfaces (HIG + Liquid Glass).

import SwiftUI

/// Primary flat-tab list canvas — matches `UIColor.systemBackground` (Messages / Activity / Community).
enum SparkFlatTabCanvas {
    static let color = Color(UIColor.systemBackground)
}

extension View {
    /// System semantic grouped canvas (`systemGroupedBackground`) behind scroll/list content.
    public func sparkScreenCanvasBackground() -> some View {
        background(Color(.systemGroupedBackground))
    }

    /// Elevated inbox/feed module: glass card on semantic canvas (not fixed white fill).
    public func sparkInboxModuleSurface() -> some View {
        padding(SparkLayoutMetrics.inboxModuleInnerPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sparkGlassSurface(RoundedRectangle.sparkCard)
    }

    /// List row chrome pairing with `sparkInboxModuleSurface()` content.
    public func sparkInboxModuleListRow() -> some View {
        listRowInsets(SparkLayoutMetrics.inboxModuleListRowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// Grouped canvas for secondary scroll surfaces (settings-adjacent lists).
    public func sparkFeedModuleScroll() -> some View {
        sparkScreenCanvasBackground()
    }

    /// Full-screen empty states on primary tab flat canvas (`background`).
    public func sparkContentUnavailableCanvas() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
    }

    /// Opaque pinned inset — legacy stacked layout only.
    public func sparkPinnedControlBar() -> some View {
        background(.bar)
    }

    /// Transparent inset chrome — pair with `sparkScrollUnderTopInset`.
    public func sparkTransparentPinnedInset() -> some View {
        background(.clear)
    }

    /// Pins chrome above scroll content via `safeAreaInset(edge: .top)` — immersive tabs only (e.g. Likes intent bar).
    /// Activity/Message filters use `sparkTabTopAccessory` under the navigation bar instead.
    public func sparkScrollUnderTopInset<Inset: View>(
        @ViewBuilder inset: () -> Inset
    ) -> some View {
        modifier(SparkScrollUnderTopInsetModifier(inset: inset()))
    }

    /// Keeps pinned inset mounted; toggles visibility without removing layout space.
    public func sparkScrollUnderTopInset<Inset: View>(
        isVisible: Bool,
        @ViewBuilder inset: () -> Inset
    ) -> some View {
        sparkScrollUnderTopInset {
            inset()
                .opacity(isVisible ? 1 : 0)
                .allowsHitTesting(isVisible)
                .accessibilityHidden(!isVisible)
        }
    }

    /// Phone Recents-style navigation bar: transparent at scroll edge, bar material when scrolled.
    /// Apply **after** `.toolbar { }` on tab roots inside `NavigationStack`.
    public func sparkPhoneStyleNavigationBar() -> some View {
        modifier(SparkPhoneStyleNavigationBarModifier())
    }

    /// Settings / wizard list row: glass module + plain-list row chrome.
    public func sparkSemanticListRow() -> some View {
        sparkInboxModuleSurface()
            .sparkInboxModuleListRow()
    }

    /// Grouped canvas list chrome (alias for settings and secondary lists).
    public func sparkSemanticListChrome() -> some View {
        sparkScreenListStyle()
    }

    /// Primary tab flat list (Profile / Community / Messages / Activity) — scrolls under transparent nav bar.
    public func sparkFlatTabListStyle() -> some View {
        modifier(SparkFlatTabListStyleModifier())
    }

    /// Row chrome for `sparkFlatTabListStyle()` lists — semantic `systemBackground` per row.
    public func sparkFlatTabListRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(SparkFlatTabCanvas.color)
            .navigationLinkIndicatorVisibility(.hidden)
    }

    /// Search / filter row content fill — same `systemBackground` as `sparkFlatTabListRow()`.
    public func sparkFlatTabRowBackground() -> some View {
        frame(maxWidth: .infinity)
            .background(SparkFlatTabCanvas.color)
    }

    /// Inbox search / filter row chrome (pairs with `sparkFlatTabRowBackground()` on content).
    public func sparkInboxSearchListRow() -> some View {
        sparkFlatTabListRow()
    }
}

// MARK: - Flat tab list style

private struct SparkFlatTabListStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(SparkFlatTabCanvas.color)
            .contentMargins(.top, 0, for: .scrollContent)
            .contentMargins(.top, 0, for: .scrollIndicators)
    }
}

// MARK: - Pinned top filter inset

private struct SparkScrollUnderTopInsetModifier<Inset: View>: ViewModifier {
    let inset: Inset

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            inset
                .frame(maxWidth: .infinity, alignment: .leading)
                .sparkTransparentPinnedInset()
        }
    }
}

// MARK: - Phone-style navigation bar

private struct SparkPhoneStyleNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .toolbarBackground(.bar, for: .navigationBar)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        } else {
            content
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
