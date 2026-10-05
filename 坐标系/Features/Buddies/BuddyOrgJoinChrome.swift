//
//  BuddyOrgJoinChrome.swift
//  坐标系
//
//  兴趣圈子加入链路 Sheet（确认 → 成功）；同一 NavigationStack 只注册一份。
//  不在 Sheet 上 `.environment(AppModel)`，避免与 Tab 根 Observation 叠加重绘卡死。
//

import CoordinateModels
import SwiftUI

extension View {
    /// 兴趣圈子加入链路 Sheet（确认 → 成功；成功后可进群聊）
    func buddyOrgJoinChrome(
        buddies: BuddiesModel,
        messages: MessagesModel,
        memberName: String,
        blockedUserNames: Set<String>,
        onBrowseBuddies: (() -> Void)? = nil,
        openCircle: ((InterestCircle) -> Void)? = nil,
        openGuild: ((CompanionGuild) -> Void)? = nil,
        openConversation: ((UUID) -> Void)? = nil
    ) -> some View {
        modifier(
            BuddyOrgJoinChromeModifier(
                buddies: buddies,
                messages: messages,
                memberName: memberName,
                blockedUserNames: blockedUserNames,
                onBrowseBuddies: onBrowseBuddies,
                openCircle: openCircle,
                openGuild: openGuild,
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
    var messages: MessagesModel
    var memberName: String
    var blockedUserNames: Set<String>
    var onBrowseBuddies: (() -> Void)?
    var openCircle: ((InterestCircle) -> Void)?
    var openGuild: ((CompanionGuild) -> Void)?
    var openConversation: ((UUID) -> Void)?

    @Environment(\.hasBuddyOrgJoinChrome) private var registered

    func body(content: Content) -> some View {
        if registered {
            content
        } else {
            content
                .environment(\.hasBuddyOrgJoinChrome, true)
                .sheet(item: $buddies.presentation.pendingOrgJoin) { target in
                    BuddyOrgJoinConfirmSheet(
                        target: target,
                        onConfirm: { confirmJoin(target) },
                        onCancel: { buddies.cancelJoin() }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
                .sheet(item: $buddies.presentation.pendingOrgJoinSuccess) { success in
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
                .sheet(item: $buddies.presentation.pendingOrgInvite) { target in
                    BuddyOrgInviteMembersSheet(
                        target: target,
                        viewerName: memberName,
                        blockedUserNames: blockedUserNames,
                        onSend: { names in
                            buddies.sendOrgInvites(nicknames: names)
                        },
                        onBrowseBuddies: onBrowseBuddies
                    )
                    .environment(buddies)
                    .environment(messages)
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
        }
    }

    private func confirmJoin(_ target: BuddyOrgJoinTarget) {
        guard buddies.confirmJoin() != nil else { return }
        if case .circle(let circle) = target {
            if let convo = messages.startCircleChat(for: circle, memberName: memberName) {
                buddies.attachJoinConversation(convo.id)
            }
        }
    }

    private func openJoined(_ success: BuddyOrgJoinSuccess) {
        switch success.kind {
        case .circle:
            if let circle = buddies.circle(named: success.name) {
                openCircle?(circle)
            }
        case .guild:
            if let guild = buddies.allGuilds.first(where: {
                $0.name.caseInsensitiveCompare(success.name) == .orderedSame
            }) {
                openGuild?(guild)
            }
        }
    }
}
