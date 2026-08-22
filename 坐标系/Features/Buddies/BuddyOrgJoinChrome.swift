//
//  BuddyOrgJoinChrome.swift
//  坐标系
//
//  兴趣圈子加入链路 Sheet（确认 → 成功）；同一 NavigationStack 只注册一份。
//

import SwiftUI

extension View {
    /// 兴趣圈子加入链路 Sheet（确认 → 成功；成功后可进群聊）
    func buddyOrgJoinChrome(
        buddies: BuddiesModel,
        openCircle: ((InterestCircle) -> Void)? = nil,
        openConversation: ((UUID) -> Void)? = nil
    ) -> some View {
        modifier(
            BuddyOrgJoinChromeModifier(
                buddies: buddies,
                openCircle: openCircle,
                openConversation: openConversation
            )
        )
    }
}

private struct BuddyOrgJoinChromeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hasBuddyOrgJoinChrome: Bool {
        get { self[BuddyOrgJoinChromeKey.self] }
        set { self[BuddyOrgJoinChromeKey.self] = newValue }
    }
}

private struct BuddyOrgJoinChromeModifier: ViewModifier {
    @Bindable var buddies: BuddiesModel
    var openCircle: ((InterestCircle) -> Void)?
    var openConversation: ((UUID) -> Void)?

    @Environment(\.hasBuddyOrgJoinChrome) private var registered
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        if registered {
            content
        } else {
            content
                .environment(\.hasBuddyOrgJoinChrome, true)
                .sheet(item: $buddies.pendingOrgJoin) { target in
                    BuddyOrgJoinConfirmSheet(
                        target: target,
                        onConfirm: { confirmJoin(target) },
                        onCancel: { buddies.cancelJoin() }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
                .sheet(item: $buddies.pendingOrgJoinSuccess) { success in
                    BuddyOrgJoinSuccessSheet(
                        success: success,
                        hasConversation: buddies.pendingOpenConversationID != nil,
                        onEnterChat: {
                            if let id = buddies.pendingOpenConversationID {
                                openConversation?(id)
                            }
                            buddies.dismissJoinSuccess()
                        },
                        onViewOrg: {
                            openJoined(success)
                            buddies.dismissJoinSuccess()
                        },
                        onDone: { buddies.dismissJoinSuccess() }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
                .sheet(item: $buddies.pendingOrgInvite) { target in
                    BuddyOrgInviteMembersSheet(target: target) { names in
                        buddies.sendOrgInvites(nicknames: names)
                    }
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
        }
    }

    private func confirmJoin(_ target: BuddyOrgJoinTarget) {
        guard buddies.confirmJoin() != nil else { return }
        if case .circle(let circle) = target {
            if let convo = messages.startCircleChat(for: circle, memberName: app.user.name) {
                buddies.attachJoinConversation(convo.id)
            }
        }
    }

    private func openJoined(_ success: BuddyOrgJoinSuccess) {
        switch success.kind {
        case .circle:
            if let circle = SampleData.interestCircles.first(where: { $0.name == success.name }) {
                openCircle?(circle)
            }
        case .guild:
            break
        }
    }
}
