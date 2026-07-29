//
//  BuddyOrgJoinChrome.swift
//  坐标系
//
//  挂在搭子 Tab / 组织详情上的加入确认、成功、邀请 Sheet。
//  主流默认：加入兴趣组织 = 进入组织群聊。
//

import SwiftUI

extension View {
    /// 兴趣组织加入链路 Sheet（确认 → 成功 → 邀请；成功后可进群聊）
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

private struct BuddyOrgJoinChromeModifier: ViewModifier {
    @Bindable var buddies: BuddiesModel
    var openCircle: ((InterestCircle) -> Void)?
    var openConversation: ((UUID) -> Void)?

    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        content
            .sheet(item: $buddies.pendingOrgJoin) { target in
                BuddyOrgJoinConfirmSheet(
                    target: target,
                    onConfirm: { confirmJoin(target) },
                    onCancel: { buddies.cancelJoin() }
                )
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
                    onInvite: {
                        beginInvite(from: success)
                        buddies.dismissJoinSuccess()
                    },
                    onDone: { buddies.dismissJoinSuccess() }
                )
            }
            .sheet(item: $buddies.pendingOrgInvite) { target in
                BuddyOrgInviteMembersSheet(target: target) { names in
                    buddies.sendOrgInvites(nicknames: names)
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

    private func beginInvite(from success: BuddyOrgJoinSuccess) {
        switch success.kind {
        case .circle:
            if let circle = SampleData.interestCircles.first(where: { $0.name == success.name }) {
                buddies.beginInvite(to: .circle(circle))
            }
        case .guild:
            break
        }
    }
}
