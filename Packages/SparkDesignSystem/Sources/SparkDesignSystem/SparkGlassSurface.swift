// Module: SparkDesignSystem — Liquid Glass (iOS 26) with Material fallback.

import SwiftUI

extension View {
    /// System glass on iOS 26+; Material fallback on earlier OS (see ios-liquid-glass.mdc).
    @ViewBuilder
    public func sparkGlassSurface<S: InsettableShape>(_ shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(in: shape)
        } else {
            background(.thickMaterial, in: shape)
        }
    }

    /// Thin glass for compact controls (toolbar chips, circular actions).
    @ViewBuilder
    public func sparkGlassControl<S: InsettableShape>(_ shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }
}
