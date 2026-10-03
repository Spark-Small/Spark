//
//  GroupManageSheet.swift
//  坐标系
//
//  群详情：对照俱乐部 `BuddyOrgInfoScaffold` 已加入态——
//  成员网格 / 群概览 / 聊天偏好 / 本群身份 / 清空·退群。
//

import SwiftUI
import CoordinateModels

struct GroupManageSheet: View {
    let conversationID: ChatConversation.ID
    var onOpenActivity: (Activity) -> Void
    var onReport: (() -> Void)? = nil

    @Environment(MessagesModel.self) var model
    @Environment(ActivitiesModel.self) var activities
    @Environment(BuddiesModel.self) var buddies
    @Environment(AppModel.self) var app
    @Environment(\.dismiss) var dismiss

    @State var navigation = TabNavigationState()
    @State var prefs = OrgMembershipPrefs.fresh()
    @State var showAllMembers = false
    @State var showMemberList = false
    @State var showQRSheet = false
    @State var showRenameSheet = false
    @State var showInviteSheet = false
    @State var confirmClearHistory = false
    @State var confirmLeave = false
    @State var feedback: String?

    private var prefsStorageKey: String {
        "messages.groupPrefs.\(conversationID.uuidString)"
    }

    var conversation: ChatConversation? {
        model.conversations.first { $0.id == conversationID }
    }

    var members: [GroupMemberRecord] {
        model.groupMembers(for: conversationID)
    }

    var otherMembers: [GroupMemberRecord] {
        members.filter {
            $0.nickname.caseInsensitiveCompare(app.user.name) != .orderedSame
        }
    }

    var relatedActivity: Activity? {
        guard let id = conversation?.relatedActivityID else { return nil }
        return activities.activity(id: id)
    }

    var isOwner: Bool {
        conversation?.isOwned(by: app.user.name) == true
    }

    var myRole: GroupMemberRole {
        model.role(of: app.user.name, in: conversationID)
    }

    var canRenameChat: Bool {
        !prefs.onlyAdminCanRename || isOwner || myRole == .admin
    }

    var memberCountLabel: Int { members.count }

    var profileSource: BuddyProfileSource { .discover }

    var body: some View {
        @Bindable var navigation = navigation

        NavigationStack(path: $navigation.path) {
            List {
                if conversation != nil {
                    memberSection
                    overviewSection
                    chatPrefsSection
                    identitySection
                    destructiveSection
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .contentMargins(.top, 0, for: .scrollContent)
            .navigationTitle(MessagesCopy.groupInfoTitle(memberCountLabel))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.close) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if onReport != nil {
                        Button(MessagesCopy.reportUser, role: .destructive) {
                            dismiss()
                            onReport?()
                        }
                    }
                }
            }
            .circleMemberSheetNavigationDestination()
            .onAppear(perform: hydratePrefs)
        }
        .tabNavigationState(navigation)
        .independentNavigationSheetChrome()
        .platformSheet(.form)
        .sheet(isPresented: $showQRSheet) {
            CircleGroupQRSheet(title: conversation?.title ?? MessagesCopy.groupSubtitle)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showRenameSheet) {
            CircleGroupRenameSheet(
                initialTitle: conversation?.title ?? "",
                onSave: { title in
                    model.renameGroup(title, for: conversationID)
                    feedback = BuddyOrgJoinCopy.chatNameUpdated
                }
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showMemberList) {
            BuddyMemberListSheet(
                title: BuddyMemberCopy.listTitle,
                members: allMemberTargets
            )
            .environment(app)
            .environment(buddies)
            .environment(model)
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showInviteSheet) {
            GroupInviteFriendsSheet(conversationID: conversationID)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert(
            MessagesCopy.clearHistoryTitle,
            isPresented: $confirmClearHistory
        ) {
            Button(MessagesCopy.clearHistoryConfirm, role: .destructive) {
                model.clearChatHistory(in: conversationID)
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text(MessagesCopy.clearHistoryMessage)
        }
        .alert(
            leaveAlertTitle,
            isPresented: $confirmLeave
        ) {
            Button(leaveActionTitle, role: .destructive) {
                leaveCurrentGroup()
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text(leaveAlertMessage)
        }
        .platformFeedbackAlert($feedback)
    }

    var leaveActionTitle: String {
        if isOwner && (conversation?.isPeerGroup == true || conversation?.isActivityGroup == true) {
            return MessagesCopy.dissolveGroup
        }
        return MessagesCopy.groupLeave
    }

    private var leaveAlertTitle: String {
        if isOwner && (conversation?.isPeerGroup == true || conversation?.isActivityGroup == true) {
            return MessagesCopy.dissolveGroupTitle
        }
        if conversation?.isPeerGroup == true {
            return MessagesCopy.leavePeerGroupTitle
        }
        return MessagesCopy.groupLeaveConfirmTitle
    }

    private var leaveAlertMessage: String {
        if isOwner && (conversation?.isPeerGroup == true || conversation?.isActivityGroup == true) {
            return MessagesCopy.dissolveGroupMessage
        }
        if conversation?.isPeerGroup == true {
            return MessagesCopy.leavePeerGroupMessage
        }
        return MessagesCopy.groupLeaveConfirmMessage
    }

    func hydratePrefs() {
        guard let conversation else { return }
        var next = loadStoredPrefs() ?? OrgMembershipPrefs.fresh()
        next.isPinned = conversation.isPinned
        next.muteNotifications = conversation.isMuted
        next.myGroupNickname = model.groupAlias(for: app.user.name, in: conversationID) ?? ""
        prefs = next
    }

    func applyPrefs(_ next: OrgMembershipPrefs) {
        let previous = prefs
        prefs = next
        storePrefs(next)
        if previous.isPinned != next.isPinned {
            model.togglePin(conversationID)
        }
        if previous.muteNotifications != next.muteNotifications {
            model.toggleMute(conversationID)
        }
    }

    func leaveCurrentGroup() {
        guard let conversation else { return }
        if conversation.isActivityGroup {
            if isOwner {
                model.dissolveGroup(conversationID: conversationID)
            } else if let activityID = conversation.relatedActivityID {
                app.cancelActivityRegistration(activityID)
            } else {
                model.requestDelete(conversation)
            }
        } else if conversation.isPeerGroup {
            if isOwner {
                model.dissolveGroup(conversationID: conversationID)
            } else {
                model.leavePeerGroup(conversationID: conversationID, leaverName: app.user.name)
            }
        } else if let circleID = conversation.relatedCircleID {
            model.leaveCircleChat(circleID: circleID, leaverName: app.user.name)
        } else {
            model.delete(conversationID)
        }
        dismiss()
    }

    private func loadStoredPrefs() -> OrgMembershipPrefs? {
        guard let data = UserDefaults.standard.data(forKey: prefsStorageKey) else { return nil }
        return try? JSONDecoder().decode(OrgMembershipPrefs.self, from: data)
    }

    private func storePrefs(_ value: OrgMembershipPrefs) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: prefsStorageKey)
    }
}
