//
//  ProfileCircleDetailView.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct ProfileCircleDetailView: View {
    let circle: InterestCircle

    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(\.tabNavigationStateRef) private var navigation
    @Environment(\.dismiss) private var dismiss

    private var isJoined: Bool { buddies.isJoined(circle) }

    private var circleConversation: ChatConversation? {
        messages.conversation(forCircleID: circle.id)
    }

    private var members: [DiscoverBuddyItem] {
        SampleData.circleBuddies
            .filter { $0.circleName == circle.name }
            .map(DiscoverBuddyItem.free)
    }

    /// 详情页标题与成员区对齐，不用浏览卡片上的种子 `memberCount`。
    private var memberCountLabel: Int {
        members.count + (isJoined ? 1 : 0)
    }

    private var profileSource: BuddyProfileSource {
        .circle(name: circle.name, topic: circle.topic)
    }

    private func memberRoleLabel(for nickname: String) -> String {
        if let id = circleConversation?.id {
            switch messages.role(of: nickname, in: id) {
            case .owner:
                return GroupMemberRole.owner.rawValue
            case .admin:
                return GroupMemberRole.admin.rawValue
            case .member:
                return BuddyMemberCopy.roleMember
            }
        }
        return BuddyMemberCopy.roleMember
    }

    private func memberProfileTarget(
        for item: DiscoverBuddyItem,
        groupAlias: String?
    ) -> BuddyMemberProfileTarget {
        BuddyMemberProfileTarget(
            item: item,
            source: profileSource,
            role: memberRoleLabel(for: item.profile.nickname),
            groupAlias: groupAlias
        )
    }

    private func selfMemberProfileTarget() -> BuddyMemberProfileTarget? {
        guard isJoined else { return nil }
        let name = app.user.name
        let groupAlias = circleConversation.flatMap {
            messages.groupAlias(for: name, in: $0.id)
        }
        return memberProfileTarget(
            for: buddies.discoverItem(
                for: name,
                fallbackCircleName: circle.name,
                fallbackTopic: circle.topic
            ),
            groupAlias: groupAlias
        )
    }

    var body: some View {
        BuddyOrgInfoScaffold(
            infoTitle: "俱乐部信息",
            nameLabel: "俱乐部名称",
            displayName: circle.name,
            memberCountLabel: memberCountLabel,
            announcement: circle.summary,
            cityLine: circle.city,
            metaRows: [
                ("主题", circle.topic),
                ("创建者", circle.creatorName),
                ("周活跃", "\(circle.weeklyActive)"),
            ],
            members: members,
            memberName: { $0.profile.nickname },
            memberTarget: { item, _ in
                memberProfileTarget(
                    for: item,
                    groupAlias: circleConversation.flatMap {
                        messages.groupAlias(for: item.profile.nickname, in: $0.id)
                    }
                )
            },
            isJoined: isJoined,
            joinTitle: "加入俱乐部",
            leaveTitle: "退出俱乐部",
            pinTitle: "置顶聊天",
            nicknameFieldTitle: "我在本群的昵称",
            kind: .circle,
            reportTargetID: circle.id,
            onRequestJoin: { buddies.beginJoin(.circle(circle)) },
            onLeave: {
                messages.leaveCircleChat(circleID: circle.id, leaverName: app.user.name)
                buddies.leaveCircle(circle)
                dismiss()
            },
            onEnterChat: { openCircleChat() },
            onInviteTap: { buddies.beginInvite(to: .circle(circle)) },
            prefs: buddies.prefs(kind: .circle, name: circle.name),
            onPrefsChange: { next in
                let previous = buddies.prefs(kind: .circle, name: circle.name)
                buddies.updatePrefs(kind: .circle, name: circle.name) { $0 = next }
                if let id = circleConversation?.id {
                    if previous.isPinned != next.isPinned {
                        messages.togglePin(id)
                    }
                    if previous.muteNotifications != next.muteNotifications {
                        messages.toggleMute(id)
                    }
                }
            },
            chatTitle: circleConversation?.title,
            circleConversationID: circleConversation?.id,
            isGroupOwner: circleConversation?.isOwned(by: app.user.name) == true,
            onSearchChat: nil,
            onClearChatHistory: {
                guard let id = circleConversation?.id else { return }
                messages.clearChatHistory(in: id)
            },
            onDissolveCircle: {
                messages.leaveCircleChat(circleID: circle.id, leaverName: app.user.name)
                if buddies.isUserCreatedClub(circle) {
                    buddies.dissolveUserClub(circle)
                } else {
                    buddies.leaveCircle(circle)
                }
                dismiss()
            },
            onRenameChat: { title in
                guard let id = circleConversation?.id else { return }
                messages.renameGroup(title, for: id)
            },
            selfMemberTarget: selfMemberProfileTarget()
        )
    }

    private func openCircleChat() {
        app.openClubGroupChatInStack(for: circle, navigation: navigation)
    }
}

