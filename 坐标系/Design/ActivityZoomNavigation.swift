//
//  ActivityZoomNavigation.swift
//  坐标系
//
//  官方 Zoom（WWDC24 / Photos）：
//  NavigationLink + matchedTransitionSource（常驻）
//  + navigationTransition(.zoom) — 系统可交互返回
//
//  clipShape 仅支持 RoundedRectangle。
//

import SwiftUI

// MARK: - Clip shapes（与静态卡片一致）

enum ActivityZoomClip {
    case card
    /// 16:9 跟进 / 热场横卡（与榜单竖海报同圆角档，角色不同）
    case rail
    /// 2:3 榜单竖海报
    case poster
    case editorial
    case fullBleed

    var shape: RoundedRectangle {
        switch self {
        case .card: PlatformMetrics.cardShape
        case .rail, .poster: PlatformMetrics.posterShape
        case .editorial: PlatformMetrics.editorialShape
        case .fullBleed: PlatformMetrics.fullBleedShape
        }
    }
}

// MARK: - Source / Destination

extension View {
    func activityZoomTransitionSource(
        id: Activity.ID,
        in namespace: Namespace.ID,
        clip: ActivityZoomClip = .card
    ) -> some View {
        matchedTransitionSource(id: id, in: namespace) { source in
            source.clipShape(clip.shape)
        }
    }

    func activityZoomNavigationTransition(
        id: Activity.ID,
        in namespace: Namespace.ID
    ) -> some View {
        navigationTransition(.zoom(sourceID: id, in: namespace))
    }

    /// Photos：`navigationDestination` + zoom；并向栈内注入 namespace 供相关卡复用
    func activityZoomNavigationDestination(
        namespace: Namespace.ID
    ) -> some View {
        self
            .environment(\.activityZoomNamespace, namespace)
            .navigationDestination(for: Activity.ID.self) { id in
                ActivityZoomDetailDestination(activityID: id, namespace: namespace)
                    .environment(\.activityZoomNamespace, namespace)
            }
    }
}

/// 当前导航栈的活动 zoom namespace（详情内相关卡与之对齐）
private struct ActivityZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var activityZoomNamespace: Namespace.ID? {
        get { self[ActivityZoomNamespaceKey.self] }
        set { self[ActivityZoomNamespaceKey.self] = newValue }
    }
}

/// 详情打开的唯一入口：无论从哪张卡片点进来都会经过这里，
/// 顺手记一次隐式浏览信号（见 ActivityEngagementStore），不用在每张卡片上重复埋点。
private struct ActivityZoomDetailDestination: View {
    let activityID: Activity.ID
    var namespace: Namespace.ID
    @Environment(ActivitiesModel.self) private var model

    var body: some View {
        ActivityDetailView(activityID: activityID)
            .activityZoomNavigationTransition(id: activityID, in: namespace)
            .onAppear { model.recordDetailView(activityID) }
    }
}

// MARK: - NavigationLink 源

/// Photos 路径：值导航 + 常驻 matchedTransitionSource
struct ActivityZoomNavigationLink<Label: View>: View {
    let activityID: Activity.ID
    var namespace: Namespace.ID
    var clip: ActivityZoomClip = .card
    @ViewBuilder var label: () -> Label

    init(
        activity: Activity,
        namespace: Namespace.ID,
        clip: ActivityZoomClip = .card,
        @ViewBuilder label: @escaping () -> Label
    ) {
        activityID = activity.id
        self.namespace = namespace
        self.clip = clip
        self.label = label
    }

    init(
        activityID: Activity.ID,
        namespace: Namespace.ID,
        clip: ActivityZoomClip = .card,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.activityID = activityID
        self.namespace = namespace
        self.clip = clip
        self.label = label
    }

    var body: some View {
        NavigationLink(value: activityID) {
            label()
        }
        .buttonStyle(.plain)
        .activityZoomTransitionSource(
            id: activityID,
            in: namespace,
            clip: clip
        )
    }
}

#Preview("Zoom navigation") {
    @Previewable @Namespace var ns
    let activity = SampleData.activities[0]
    let app = AppModel()
    return NavigationStack {
        ActivityFeaturedCard(
            activity: activity,
            zoomNamespace: ns
        )
        .aspectRatio(PlatformMetrics.featuredCardAspectRatio, contentMode: .fit)
        .activityZoomNavigationDestination(namespace: ns)
    }
    .environment(app.activities)
}
