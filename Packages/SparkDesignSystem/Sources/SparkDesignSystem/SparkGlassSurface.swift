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

    /// Maximum-transparency glass plate (photo overlays, legibility bands).
    /// iOS 26: default `glassEffect(in:)`; iOS 17–25: `ultraThinMaterial`.
    @ViewBuilder
    public func sparkThinGlassSurface<S: InsettableShape>(_ shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
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
