//
//  ActivityZoomNavigation.swift
//  坐标系
//
//  NavigationLink + matchedTransitionSource + navigationTransition(.zoom)
//

import SwiftUI

// MARK: - Clip

enum ActivityZoomClip {
    case card
    /// 16:9 跟进 / 热场横卡
    case rail
    /// 2:3 榜单竖海报
    case poster
    case editorial
    /// 「我的」长条凭证
    case passStrip

    var shape: RoundedRectangle {
        switch self {
        case .card: PlatformMetrics.cardShape
        case .rail, .poster: PlatformMetrics.posterShape
        case .editorial: PlatformMetrics.editorialShape
        case .passStrip: PlatformMetrics.walletPassStripBarShape
        }
    }
}

// MARK: - Source identity

/// Zoom 目的意图：发现浏览进详情；「我的」凭证长条 Zoom 展开完整票面。
enum ActivityZoomIntent: Hashable {
    case browseDetail
    /// 长条凭证 → 展开完整票面（无中间履约页）
    case participantPass
}

/// Zoom 源 id，同时作为导航值。同一活动可出现在多条货架，故用 slot 保证 namespace 内唯一。
struct ActivityZoomSource: Hashable {
    let activityID: Activity.ID
    var slot: String = ""
    var intent: ActivityZoomIntent = .browseDetail
}

// MARK: - Engagement（转场后再写，避免改源列表）

enum ActivityZoomEngagement {
    static let postTransitionDelay: Duration = .milliseconds(450)

    @MainActor
    static func recordAfterTransition(
        activityID: Activity.ID,
        model: ActivitiesModel
    ) async {
        do {
            try await Task.sleep(for: postTransitionDelay)
        } catch {
            return
        }
        guard !Task.isCancelled else { return }
        model.recordDetailView(activityID)
    }
}

// MARK: - Source / Destination

extension View {
    func activityZoomTransitionSource(
        _ source: ActivityZoomSource,
        in namespace: Namespace.ID,
        clip: ActivityZoomClip = .card
    ) -> some View {
        matchedTransitionSource(id: source, in: namespace) { configuration in
            configuration.clipShape(clip.shape)
        }
    }

    func activityZoomNavigationTransition(
        _ source: ActivityZoomSource,
        in namespace: Namespace.ID
    ) -> some View {
        navigationTransition(.zoom(sourceID: source, in: namespace))
    }

    /// 货架 / 精选分区：同一活动在不同位置各拿唯一源 id
    func activityZoomSlot(_ slot: String) -> some View {
        environment(\.activityZoomSlot, slot)
    }

    /// 栈根注册 Zoom 目的地；按 intent 进详情或展开凭证票面。
    func activityZoomNavigationDestination(
        namespace: Namespace.ID
    ) -> some View {
        self
            .environment(\.activityZoomNamespace, namespace)
            .navigationDestination(for: ActivityZoomSource.self) { source in
                switch source.intent {
                case .browseDetail:
                    ActivityZoomDetailDestination(source: source, namespace: namespace)
                case .participantPass:
                    ActivityCredentialExpandedDestination(source: source, namespace: namespace)
                }
            }
    }

    /// 仅当外层尚未注册时再挂（如「我的」凭证夹）。自有 NavigationStack 的 Sheet 应直接用上方 API。
    func activityZoomNavigationDestinationIfNeeded(
        fallback namespace: Namespace.ID
    ) -> some View {
        modifier(ActivityZoomStackRegistration(fallback: namespace))
    }
}

/// 统一详情入口：Zoom + 延后浏览埋点
struct ActivityZoomDetailDestination: View {
    let source: ActivityZoomSource
    let namespace: Namespace.ID
    @Environment(ActivitiesModel.self) private var model

    var body: some View {
        ActivityDetailView(activityID: source.activityID)
            .activityZoomNavigationTransition(source, in: namespace)
            .task(id: source.activityID) {
                await ActivityZoomEngagement.recordAfterTransition(
                    activityID: source.activityID,
                    model: model
                )
            }
    }
}

/// 「我的」凭证 Zoom 落点：展开为完整票面（现有 WalletPassFace 样式）。
struct ActivityCredentialExpandedDestination: View {
    let source: ActivityZoomSource
    let namespace: Namespace.ID

    var body: some View {
        ActivityCredentialExpandedView(activityID: source.activityID)
            .activityZoomNavigationTransition(source, in: namespace)
    }
}

private struct ActivityZoomStackRegistration: ViewModifier {
    @Environment(\.activityZoomNamespace) private var inherited
    let fallback: Namespace.ID

    func body(content: Content) -> some View {
        if inherited == nil {
            content.activityZoomNavigationDestination(namespace: fallback)
        } else {
            content
        }
    }
}

private struct ActivityZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

private struct ActivityZoomSlotKey: EnvironmentKey {
    static let defaultValue = ""
}

extension EnvironmentValues {
    var activityZoomNamespace: Namespace.ID? {
        get { self[ActivityZoomNamespaceKey.self] }
        set { self[ActivityZoomNamespaceKey.self] = newValue }
    }

    var activityZoomSlot: String {
        get { self[ActivityZoomSlotKey.self] }
        set { self[ActivityZoomSlotKey.self] = newValue }
    }
}

// MARK: - NavigationLink

struct ActivityZoomNavigationLink<Label: View>: View {
    let activityID: Activity.ID
    var namespace: Namespace.ID
    var clip: ActivityZoomClip = .card
    var intent: ActivityZoomIntent = .browseDetail
    @ViewBuilder var label: () -> Label

    @Environment(\.activityZoomSlot) private var slot

    init(
        activity: Activity,
        namespace: Namespace.ID,
        clip: ActivityZoomClip = .card,
        intent: ActivityZoomIntent = .browseDetail,
        @ViewBuilder label: @escaping () -> Label
    ) {
        activityID = activity.id
        self.namespace = namespace
        self.clip = clip
        self.intent = intent
        self.label = label
    }

    init(
        activityID: Activity.ID,
        namespace: Namespace.ID,
        clip: ActivityZoomClip = .card,
        intent: ActivityZoomIntent = .browseDetail,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.activityID = activityID
        self.namespace = namespace
        self.clip = clip
        self.intent = intent
        self.label = label
    }

    var body: some View {
        let source = ActivityZoomSource(activityID: activityID, slot: slot, intent: intent)
        NavigationLink(value: source) {
            label()
        }
        .buttonStyle(.plain)
        .activityZoomTransitionSource(source, in: namespace, clip: clip)
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
