//
//  PlatformChromeMeasurements.swift
//  坐标系
//
//  系统控件尺寸：在 View / MainActor 上用 SwiftUI glass 按钮 + PreferenceKey 实测，
//  避免在静态 PlatformMetrics 里探测 UIKit。
//

import SwiftUI
import UIKit

// MARK: - Store

@Observable
@MainActor
final class PlatformChromeMeasurements {
    private(set) var navigationBarButtonSide: CGFloat
    private(set) var composerToolHeight: CGFloat
    private(set) var composerFieldVerticalPadding: CGFloat

    init(
        navigationBarButtonSide: CGFloat = PlatformChromeMeasurements.fallbackNavigationBarButtonSide,
        composerToolHeight: CGFloat = PlatformChromeMeasurements.fallbackComposerToolHeight,
        composerFieldVerticalPadding: CGFloat = PlatformChromeMeasurements.fallbackComposerFieldVerticalPadding
    ) {
        self.navigationBarButtonSide = navigationBarButtonSide
        self.composerToolHeight = composerToolHeight
        self.composerFieldVerticalPadding = composerFieldVerticalPadding
    }

    static var fallbackNavigationBarButtonSide: CGFloat {
        let body = UIFont.preferredFont(forTextStyle: .body).pointSize
        return max(36, (body * (40.0 / 17.0)).rounded(.toNearestOrAwayFromZero))
    }

    static var fallbackComposerToolHeight: CGFloat {
        let body = UIFont.preferredFont(forTextStyle: .body).pointSize
        return (body * 2.4).rounded(.toNearestOrAwayFromZero)
    }

    static var fallbackComposerFieldVerticalPadding: CGFloat {
        let body = UIFont.preferredFont(forTextStyle: .body).pointSize
        return max(4, (body * 0.35).rounded(.toNearestOrAwayFromZero))
    }

    func updateNavigationBarButtonSide(_ side: CGFloat) {
        guard side > 0, abs(side - navigationBarButtonSide) > 0.5 else { return }
        navigationBarButtonSide = side
    }

    func updateComposerToolHeight(_ height: CGFloat) {
        guard height > 0, abs(height - composerToolHeight) > 0.5 else { return }
        composerToolHeight = height
        let body = UIFont.preferredFont(forTextStyle: .body).lineHeight
        let derived = max(4, ((height - body) * 0.5).rounded(.toNearestOrAwayFromZero))
        if derived > composerFieldVerticalPadding - 0.5 {
            composerFieldVerticalPadding = derived
        }
    }
}

// MARK: - Environment（@MainActor store 用 EnvironmentKey + 惰性默认，勿 `@Entry`）

private enum PlatformChromeMeasurementsKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: PlatformChromeMeasurements = MainActor.assumeIsolated {
        PlatformChromeMeasurements()
    }
}

extension EnvironmentValues {
    var platformChromeMeasurements: PlatformChromeMeasurements {
        get { self[PlatformChromeMeasurementsKey.self] }
        set { self[PlatformChromeMeasurementsKey.self] = newValue }
    }
}

// MARK: - Window 根

/// App `WindowGroup` 根容器：持有一份 `@State` store，向下注入并挂载探针。
struct PlatformChromeRoot<Content: View>: View {
    @State private var measurements = PlatformChromeMeasurements()
    @ViewBuilder private var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .platformChromeMeasurements(measurements)
    }
}

// MARK: - Probe

/// 零尺寸 background：用与顶栏 / 输入栏同族的 SwiftUI glass 按钮实测边长。
private struct PlatformChromeMeasurementProbe: View {
    let measurements: PlatformChromeMeasurements
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 0) {
            Button("", systemImage: "ellipsis") { }
                .labelStyle(.iconOnly)
                .platformToolbarCircleStyle()
                .fixedSize()
                .measurePlatformChromeDimension { side in
                    measurements.updateNavigationBarButtonSide(side)
                }

            Button("", systemImage: "plus") { }
                .labelStyle(.iconOnly)
                .platformComposerCircleStyle()
                .fixedSize()
                .measurePlatformChromeDimension { side in
                    measurements.updateComposerToolHeight(side)
                }
        }
        .frame(width: 0, height: 0)
        .hidden()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
        .id(dynamicTypeSize)
    }
}

extension View {
    /// 覆写 Environment 默认 store，并在 background 挂载实测探针（探针用参数持有 store，勿 `@Environment` 读自身）。
    func platformChromeMeasurements(_ measurements: PlatformChromeMeasurements) -> some View {
        environment(\.platformChromeMeasurements, measurements)
            .background {
                PlatformChromeMeasurementProbe(measurements: measurements)
            }
    }

    /// Preview / 测试：公式初值 + 探针（布局后收敛到系统实测）。
    func platformChromeMeasurementsEnvironment() -> some View {
        platformChromeMeasurements(PlatformChromeMeasurements())
    }
}

// MARK: - Preference

private enum PlatformChromeDimensionKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func measurePlatformChromeDimension(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PlatformChromeDimensionKey.self,
                    value: max(proxy.size.width, proxy.size.height)
                )
            }
        }
        .onPreferenceChange(PlatformChromeDimensionKey.self) { dimension in
            guard dimension > 0 else { return }
            onChange(dimension)
        }
    }
}
