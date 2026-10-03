//
//  CircleGroupManageViews.swift
//  坐标系
//
//  圈子群管理子页（文案见 CircleGroupManageCopy.swift）。
//

import SwiftUI
import CoordinateModels

struct CircleGroupManageView: View {
    static let maxAdminCount = 3

    let conversationID: UUID
    let displayName: String
    var prefs: OrgMembershipPrefs
    var onPrefsChange: (OrgMembershipPrefs) -> Void
    var onDissolve: () -> Void

    @Environment(MessagesModel.self) private var messages
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDissolve = false
    @State private var showTransferSheet = false
    @State private var showAddAdminSheet = false
    @State private var pendingRemoveAdmin: String?

    private var conversation: ChatConversation? {
        messages.conversations.first { $0.id == conversationID }
    }

    private var circleProfileSource: BuddyProfileSource {
        if let circle = buddies.circle(named: displayName) {
            return .circle(name: circle.name, topic: circle.topic)
        }
        return .circle(name: displayName, topic: "")
    }

    private var roster: [GroupMemberRecord] {
        messages.groupMembers(for: conversationID)
    }

    private var isOwner: Bool {
        conversation?.isOwned(by: app.user.name) == true
    }

    private var ownerMember: GroupMemberRecord? {
        roster.first { $0.role == .owner }
    }

    private var admins: [GroupMemberRecord] {
        roster.filter { $0.role == .admin }
    }

    private var adminCandidates: [GroupMemberRecord] {
        roster.filter { $0.role == .member }
    }

    private var transferCandidates: [GroupMemberRecord] {
        roster.filter { $0.role != .owner }
    }

    var body: some View {
        List {
            if let ownerMember {
                Section {
                    ownerMemberRow(ownerMember)
                } header: {
                    Text(CircleGroupCopy.owner)
                }
            }

            Section {
                Toggle(CircleGroupCopy.allowJoinViaQR, isOn: ownerPrefBinding(\.allowJoinViaQR))
                    .disabled(!isOwner)
                Toggle(CircleGroupCopy.joinRequiresApproval, isOn: ownerPrefBinding(\.joinRequiresApproval))
                    .disabled(!isOwner)
                Toggle(CircleGroupCopy.onlyAdminCanRename, isOn: ownerPrefBinding(\.onlyAdminCanRename))
                    .disabled(!isOwner)
            } footer: {
                Text(isOwner ? CircleGroupManageCopy.ownerRulesFooter : CircleGroupManageCopy.nonOwnerRulesFooter)
            }

            if isOwner {
                Section {
                    Button(CircleGroupCopy.transferOwnership) {
                        showTransferSheet = true
                    }
                    .disabled(transferCandidates.isEmpty)
                }

                Section {
                    ForEach(admins) { admin in
                        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                            PlatformListAvatarView(name: admin.nickname, side: 36)
                            Text(admin.nickname)
                            Spacer(minLength: 0)
                            Button(CircleGroupCopy.removeAdmin, role: .destructive) {
                                pendingRemoveAdmin = admin.nickname
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    if admins.count < Self.maxAdminCount {
                        Button(CircleGroupCopy.addAdmin) {
                            showAddAdminSheet = true
                        }
                        .disabled(adminCandidates.isEmpty)
                    }
                } header: {
                    Text(CircleGroupCopy.admins)
                } footer: {
                    Text(CircleGroupCopy.adminFooter)
                }

                Section {
                    Button(CircleGroupCopy.dissolve, role: .destructive) {
                        confirmDissolve = true
                    }
                }
            }
        }
        .navigationTitle(CircleGroupCopy.manage)
        .navigationBarTitleDisplayMode(.inline)
        .alert(CircleGroupManageCopy.dissolveTitle, isPresented: $confirmDissolve) {
            Button(CircleGroupCopy.dissolve, role: .destructive) {
                onDissolve()
                dismiss()
            }
            Button(CircleGroupManageCopy.cancel, role: .cancel) {}
        } message: {
            Text(CircleGroupManageCopy.dissolveBody)
        }
        .confirmationDialog(
            CircleGroupManageCopy.removeAdminTitle,
            isPresented: Binding(
                get: { pendingRemoveAdmin != nil },
                set: { if !$0 { pendingRemoveAdmin = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(CircleGroupManageCopy.remove, role: .destructive) {
                if let name = pendingRemoveAdmin {
                    messages.removeGroupAdmin(name, in: conversationID)
                }
                pendingRemoveAdmin = nil
            }
            Button(CircleGroupManageCopy.cancel, role: .cancel) {
                pendingRemoveAdmin = nil
            }
        } message: {
            if let name = pendingRemoveAdmin {
                Text(CircleGroupManageCopy.removeAdminBody(name))
            }
        }
        .sheet(isPresented: $showTransferSheet) {
            CircleGroupTransferSheet(
                groupName: displayName,
                candidates: transferCandidates.map(\.nickname)
            ) { name in
                messages.transferGroupOwnership(to: name, in: conversationID)
            }
        }
        .sheet(isPresented: $showAddAdminSheet) {
            CircleGroupAddAdminSheet(candidates: adminCandidates.map(\.nickname)) { name in
                messages.addGroupAdmin(name, in: conversationID)
            }
        }
    }

    private func ownerPrefBinding(_ keyPath: WritableKeyPath<OrgMembershipPrefs, Bool>) -> Binding<Bool> {
        Binding(
            get: { prefs[keyPath: keyPath] },
            set: { newValue in
                guard isOwner else { return }
                var next = prefs
                next[keyPath: keyPath] = newValue
                onPrefsChange(next)
            }
        )
    }

    @ViewBuilder
    private func ownerMemberRow(_ owner: GroupMemberRecord) -> some View {
        let groupAlias = messages.groupAlias(for: owner.nickname, in: conversationID)
        let item = buddies.discoverItem(
            for: owner.nickname,
            fallbackCircleName: displayName,
            fallbackTopic: {
                guard BuddiesSupplyPolicy.allowsSampleDiscoverCatalog else { return "" }
                return SampleData.interestCircles.first(where: { $0.name == displayName })?.topic ?? ""
            }()
        )
        CircleMemberNavigationLink(
            item: item,
            source: circleProfileSource,
            groupAlias: groupAlias
        ) {
            ownerMemberLabel(owner)
        }
    }

    private func ownerMemberLabel(_ owner: GroupMemberRecord) -> some View {
        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
            PlatformListAvatarView(name: owner.nickname, side: 36)
            Text(owner.nickname)
            Spacer(minLength: 0)
            Text(GroupMemberRole.owner.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .accessibilityHint(BuddyMemberCopy.profileTitle)
    }
}

