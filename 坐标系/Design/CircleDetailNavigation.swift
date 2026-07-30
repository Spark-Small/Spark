//
//  CircleDetailNavigation.swift
//  坐标系
//
//  组织详情目的地：同一 NavigationStack 内只保留一份注册。
//  SwiftUI 对同类型的重复 `navigationDestination` 只会用最靠近栈根的那个，
//  二级页再注册一次除了打警告没有别的作用。
//

import SwiftUI

extension View {
    /// 注册组织详情目的地；本栈已注册过就跳过
    func circleDetailNavigationDestination() -> some View {
        modifier(CircleDetailDestination())
    }
}

private struct CircleDetailDestinationKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hasCircleDetailDestination: Bool {
        get { self[CircleDetailDestinationKey.self] }
        set { self[CircleDetailDestinationKey.self] = newValue }
    }
}

private struct CircleDetailDestination: ViewModifier {
    @Environment(\.hasCircleDetailDestination) private var registered

    func body(content: Content) -> some View {
        if registered {
            content
        } else {
            content
                .environment(\.hasCircleDetailDestination, true)
                .navigationDestination(for: InterestCircle.self) { circle in
                    ProfileCircleDetailView(circle: circle)
                }
        }
    }
}
