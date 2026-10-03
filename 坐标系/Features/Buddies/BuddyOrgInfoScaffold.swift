//
//  BuddyOrgInfoScaffold.swift
//  坐标系
//
//  兴趣圈子 / 陪玩工会详情骨架与成员网格。
//

import SwiftUI
import CoordinateModels

/// 圈子「群资料」骨架（主流：加入 = 进圈子群）
struct BuddyOrgInfoScaffold<Member: Identifiable>: View {
    let infoTitle: String
    let nameLabel: String
    let displayName: String
    let memberCountLabel: Int
    let announcement: String
    let cityLine: String
    let metaRows: [(title: String, value: String)]
    let members: [Member]
    let memberName: (Member) -> String
    let memberTarget: (Member, Int) -> BuddyMemberProfileTarget?
    let isJoined: Bool
    let joinTitle: String
    let leaveTitle: String
    let pinTitle: String
    let nicknameFieldTitle: String
    let kind: OrgMembershipKind
    let reportTargetID: UUID
    var onRequestJoin: () -> Void
    var onLeave: () -> Void
    var onEnterChat: (() -> Void)? = nil
    var onInviteTap: () -> Void
    var prefs: OrgMembershipPrefs
    var onPrefsChange: (OrgMembershipPrefs) -> Void
    var onBookMember: ((PaidCompanion) -> Void)? = nil
    /// 圈子群聊：会话标题（有则优先于 displayName）
    var chatTitle: String? = nil
    var circleConversationID: UUID? = nil
    var isGroupOwner: Bool = false
    var onSearchChat: (() -> Void)? = nil
    var onClearChatHistory: (() -> Void)? = nil
    var onDissolveCircle: (() -> Void)? = nil
    var onRenameChat: ((String) -> Void)? = nil
    /// 已加入时「我」的头像入口；未提供则不可点
    var selfMemberTarget: BuddyMemberProfileTarget? = nil

    @Environment(AppModel.self) var app
    @Environment(MessagesModel.self) var messages
    @Environment(BuddiesModel.self) var buddies
    @State var showAllMembers = false
    @State var confirmLeave = false
    @State var confirmClearHistory = false
    @State var showMemberList = false
    @State var showReportSheet = false
    @State var reportReceivedMessage: String?
    @State var showQRSheet = false
    @State var showRenameSheet = false
    @State var circleActionMessage: String?

    var resolvedChatTitle: String {
        chatTitle ?? displayName
    }

    var myGroupRole: GroupMemberRole {
        guard let circleConversationID else { return .member }
        return messages.role(of: app.user.name, in: circleConversationID)
    }

    var canRenameChat: Bool {
        !prefs.onlyAdminCanRename || isGroupOwner || myGroupRole == .admin
    }

    let columns = Array(
        repeating: GridItem(.flexible(), spacing: PlatformMetrics.cardInfoSpacing),
        count: 5
    )

    var visibleMembers: [Member] {
        if showAllMembers { return members }
        return Array(members.prefix(9))
    }

    var canExpandMembers: Bool {
        members.count > 9
    }

    var allMemberTargets: [BuddyMemberProfileTarget] {
        members.enumerated().compactMap { memberTarget($0.element, $0.offset) }
    }

    var body: some View {
        List {
            memberSection

            if isJoined {
                if kind == .circle {
                    circleOverviewSection
                    circleChatPrefsSection
                    circleIdentitySection
                    circleClearHistorySection
                    circleLeaveSection
                } else {
                    joinedInfoSection
                    joinedPreferencesSection
                    joinedManagementSection
                }
            } else {
                metadataSection
                Section {
                    Button(joinTitle, action: onRequestJoin)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .navigationTitle("\(infoTitle) (\(memberCountLabel))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isJoined {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(BuddyOrgJoinCopy.report, role: .destructive) {
                        showReportSheet = true
                    }
                }
            }
        }
        .alert(
            BuddyOrgJoinCopy.reportSubmittedTitle,
            isPresented: Binding(
                get: { reportReceivedMessage != nil },
                set: { if !$0 { reportReceivedMessage = nil } }
            )
        ) {
            Button(BuddyOrgJoinCopy.ok, role: .cancel) {}
        } message: {
            Text(reportReceivedMessage ?? "")
        }
        .alert(
            leaveTitle,
            isPresented: $confirmLeave
        ) {
            Button(leaveTitle, role: .destructive, action: onLeave)
            Button(BuddyOrgJoinCopy.cancel, role: .cancel) {}
        } message: {
            Text(
                kind == .circle
                    ? BuddyOrgJoinCopy.leaveCircleBody
                    : BuddyOrgJoinCopy.leaveGuildBody
            )
        }
        .alert(
            BuddyOrgJoinCopy.clearChatConfirmTitle,
            isPresented: $confirmClearHistory
        ) {
            Button(BuddyOrgJoinCopy.clearChat, role: .destructive) {
                onClearChatHistory?()
                circleActionMessage = BuddyOrgJoinCopy.clearChatDone
            }
            Button(BuddyOrgJoinCopy.cancel, role: .cancel) {}
        } message: {
            Text(BuddyOrgJoinCopy.clearChatConfirmBody)
        }
        .alert(
            BuddyOrgJoinCopy.alertTitle,
            isPresented: Binding(
                get: { circleActionMessage != nil },
                set: { if !$0 { circleActionMessage = nil } }
            )
        ) {
            Button(BuddyOrgJoinCopy.ok, role: .cancel) {}
        } message: {
            Text(circleActionMessage ?? "")
        }
        .sheet(isPresented: $showQRSheet) {
            CircleGroupQRSheet(title: resolvedChatTitle)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showRenameSheet) {
            CircleGroupRenameSheet(
                initialTitle: resolvedChatTitle,
                onSave: { title in
                    onRenameChat?(title)
                    circleActionMessage = BuddyOrgJoinCopy.chatNameUpdated
                }
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showMemberList) {
            BuddyMemberListSheet(
                title: BuddyMemberCopy.listTitle,
                members: allMemberTargets,
                onBook: onBookMember
            )
            .environment(app)
            .environment(buddies)
            .environment(messages)
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showReportSheet) {
            BuddyOrgReportSheet(targetName: displayName, kind: kind) { reason, detail, evidenceCount in
                submitReport(reason: reason, detail: detail, evidenceCount: evidenceCount)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    var muteBinding: Binding<Bool> {
        Binding(
            get: { prefs.muteNotifications },
            set: { value in
                var next = prefs
                next.muteNotifications = value
                onPrefsChange(next)
            }
        )
    }

    var pinBinding: Binding<Bool> {
        Binding(
            get: { prefs.isPinned },
            set: { value in
                var next = prefs
                next.isPinned = value
                onPrefsChange(next)
            }
        )
    }

    var nicknamesBinding: Binding<Bool> {
        Binding(
            get: { prefs.showMemberNicknames },
            set: { value in
                var next = prefs
                next.showMemberNicknames = value
                onPrefsChange(next)
            }
        )
    }

    func submitReport(reason: String, detail: String, evidenceCount: Int) {
        var parts = [reason, detail]
        if evidenceCount > 0 {
            parts.append(BuddyOrgJoinCopy.attachmentCount(evidenceCount))
        }
        app.addModerationTicket(
            postID: reportTargetID,
            title: displayName,
            reason: parts.joined(separator: " · "),
            targetKind: kind == .circle ? .circle : .guild
        )
        reportReceivedMessage = BuddyOrgReportCopy.receivedMessage(kind: kind)
    }


}
