//
//  CircleDetailNavigation.swift
//  坐标系
//
//  圈子浏览：Tab 单层 NavigationStack + 程序化 path（Apple Understanding the navigation stack）
//

import CoordinateModels
import Observation
import SwiftUI

// MARK: - Stack state

/// Tab / Sheet 导航栈状态（Apple `@Observable` + `NavigationStack(path:)` 示例同款）
@Observable
@MainActor
final class TabNavigationState {
    var path = NavigationPath()

    var isEmpty: Bool { path.isEmpty }

    func openCircle(_ circle: InterestCircle) {
        path.append(CircleBrowseRoute.circle(circle))
    }

    /// 圈子页上只保留一层成员详情：先 pop 已有成员，再 push
    func pushMember(
        item: DiscoverBuddyItem,
        source: BuddyProfileSource,
        groupAlias: String? = nil
    ) {
        let route = CircleBrowseRoute.member(
            item: item,
            source: source,
            groupAlias: groupAlias
        )
        let base = path.count
        while path.count > base {
            path.removeLast()
        }
        path.append(route)
    }

    func popLast() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func reset() {
        path = NavigationPath()
    }
}

// MARK: - Route

/// 圈子浏览栈路由（与 BuddyZoomRoute 分流，同一 Tab 单层栈共存）
enum CircleBrowseRoute: Hashable {
    case circle(InterestCircle)
    case member(item: DiscoverBuddyItem, source: BuddyProfileSource, groupAlias: String? = nil)
}

extension BuddyProfileSource {
    func isCircleSource(named circleName: String) -> Bool {
        if case .circle(let name, _) = self { return name == circleName }
        return false
    }
}

// MARK: - Stack chrome

extension View {
    /// 注入与 `NavigationStack(path:)` 绑定的导航状态
    func tabNavigationState(_ state: TabNavigationState) -> some View {
        environment(state)
            .environment(\.tabNavigationStateRef, state)
    }

    /// Tab 栈根：圈子详情 + 成员详情
    func circleBrowseNavigationDestination() -> some View {
        modifier(CircleBrowseDestination())
    }

    /// Sheet 内独立 `NavigationStack`：清掉 Tab 继承的注册标记，避免 destination 被跳过。
    func independentNavigationSheetChrome(
        resetMemberSheetDestination: Bool = false
    ) -> some View {
        modifier(
            IndependentNavigationSheetChrome(
                resetMemberSheetDestination: resetMemberSheetDestination
            )
        )
    }

    func circleBrowseStackChrome(
        buddies: BuddiesModel,
        openCircle: @escaping (InterestCircle) -> Void,
        openConversation: @escaping (UUID) -> Void
    ) -> some View {
        circleBrowseNavigationDestination()
            .circlePeerChatNavigationDestination()
            .buddyOrgJoinChrome(
                buddies: buddies,
                openCircle: openCircle,
                openConversation: openConversation
            )
    }

    /// Sheet 内独立 NavigationStack 的成员目的地
    func circleMemberSheetNavigationDestination() -> some View {
        modifier(CircleMemberSheetDestination())
    }
}

// MARK: - Club group chat destination

private struct CirclePeerChatDestinationKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hasCirclePeerChatDestination: Bool {
        get { self[CirclePeerChatDestinationKey.self] }
        set { self[CirclePeerChatDestinationKey.self] = newValue }
    }
}

extension View {
    /// 俱乐部浏览栈：`PeerChatRoute` 与资料 / 成员页共用单层栈
    func circlePeerChatNavigationDestination() -> some View {
        modifier(CirclePeerChatDestinationModifier())
    }
}

private struct CirclePeerChatDestinationModifier: ViewModifier {
    @Environment(\.hasCirclePeerChatDestination) private var registered
    @Environment(TabNavigationState.self) private var navigation

    func body(content: Content) -> some View {
        if registered {
            content
        } else {
            content
                .environment(\.hasCirclePeerChatDestination, true)
                .navigationDestination(for: PeerChatRoute.self) { route in
                    ConversationDetailView(
                        conversationID: route.conversationID,
                        chatContext: route.chatContext,
                        onOpenCircleInfo: { circle in
                            navigation.openCircle(circle)
                        }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .environment(navigation)
                }
        }
    }
}

// MARK: - Member link

/// 圈子成员入口：改 path 程序化 push（Apple value-destination + path.append）
struct CircleMemberNavigationLink<Label: View>: View {
    let item: DiscoverBuddyItem
    let source: BuddyProfileSource
    var groupAlias: String? = nil
    @ViewBuilder var label: () -> Label

    @Environment(TabNavigationState.self) private var navigation

    var body: some View {
        Button {
            navigation.pushMember(
                item: item,
                source: source,
                groupAlias: groupAlias
            )
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Environment

private struct CircleBrowseDestinationKey: EnvironmentKey {
    static let defaultValue = false
}

private struct CircleMemberSheetDestinationKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// 活动 / 搭子等 Tab 栈的 `NavigationStack(path:)`；Sheet 或未注入时为 `nil`。
    @Entry var tabNavigationStateRef: TabNavigationState? = nil
}

extension EnvironmentValues {
    var hasCircleBrowseDestination: Bool {
        get { self[CircleBrowseDestinationKey.self] }
        set { self[CircleBrowseDestinationKey.self] = newValue }
    }

    var hasCircleMemberSheetDestination: Bool {
        get { self[CircleMemberSheetDestinationKey.self] }
        set { self[CircleMemberSheetDestinationKey.self] = newValue }
    }
}

// MARK: - Sheet chrome

private struct IndependentNavigationSheetChrome: ViewModifier {
    var resetMemberSheetDestination: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let chrome = resetInheritedDestinations(content)
        if resetMemberSheetDestination {
            chrome.environment(\.hasCircleMemberSheetDestination, false)
        } else {
            chrome
        }
    }

    private func resetInheritedDestinations(_ content: Content) -> some View {
        content
            .environment(\.hasCircleBrowseDestination, false)
            .environment(\.hasBuddyZoomDestination, false)
            .environment(\.hasActivityPeerChatDestination, false)
            .environment(\.buddyZoomNamespace, nil)
    }
}

// MARK: - Destinations

private struct CircleBrowseDestination: ViewModifier {
    @Environment(\.hasCircleBrowseDestination) private var registered
    @Environment(TabNavigationState.self) private var navigation

    func body(content: Content) -> some View {
        if registered {
            content
        } else {
            content
                .environment(\.hasCircleBrowseDestination, true)
                .navigationDestination(for: CircleBrowseRoute.self) { route in
                    circleBrowseDestination(for: route)
                        .toolbarVisibility(.hidden, for: .tabBar)
                        .environment(navigation)
                }
        }
    }
}

private struct CircleMemberSheetDestination: ViewModifier {
    @Environment(\.hasCircleMemberSheetDestination) private var registered
    @Environment(TabNavigationState.self) private var navigation

    func body(content: Content) -> some View {
        if registered {
            content
        } else {
            content
                .environment(\.hasCircleMemberSheetDestination, true)
                .navigationDestination(for: CircleBrowseRoute.self) { route in
                    if case .member(let item, let source, let groupAlias) = route {
                        BuddyDetailRouteView(
                            item: item,
                            source: source,
                            groupAlias: groupAlias
                        )
                        .toolbarVisibility(.hidden, for: .tabBar)
                        .environment(navigation)
                    }
                }
        }
    }
}

@MainActor
@ViewBuilder
private func circleBrowseDestination(for route: CircleBrowseRoute) -> some View {
    switch route {
    case .circle(let circle):
        ProfileCircleDetailView(circle: circle)
    case .member(let item, let source, let groupAlias):
        BuddyDetailRouteView(
            item: item,
            source: source,
            groupAlias: groupAlias
        )
    }
}
