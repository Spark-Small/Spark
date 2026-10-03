//
//  GroupManageSheet+Members.swift
//  坐标系
//
//  群详情成员网格（对照 BuddyOrgInfoScaffold+Members）。
//

import SwiftUI
import CoordinateModels

extension GroupManageSheet {
    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: PlatformMetrics.cardInfoSpacing),
            count: 5
        )
    }

    private var visibleOthers: [GroupMemberRecord] {
        if showAllMembers { return otherMembers }
        return Array(otherMembers.prefix(9))
    }

    private var canExpandMembers: Bool {
        otherMembers.count > 9
    }

    var allMemberTargets: [BuddyMemberProfileTarget] {
        members.compactMap { memberProfileTarget(for: $0) }
    }

    var memberSection: some View {
        Section {
            if members.isEmpty {
                ContentUnavailableView {
                    Label(BuddyMemberCopy.emptyMembersTitle, systemImage: "person.2")
                } description: {
                    Text(BuddyMemberCopy.emptyMembersDescription)
                } actions: {
                    Button(BuddyMemberCopy.emptyMembersInviteCTA) {
                        showInviteSheet = true
                    }
                    .activityPrimaryCTA(controlSize: .regular)
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, PlatformMetrics.minContentGap)
            } else {
                LazyVGrid(columns: columns, spacing: PlatformMetrics.cardInfoSpacing) {
                    selfMemberCell
                    ForEach(visibleOthers) { member in
                        memberCell(member)
                    }
                    addMemberCell
                }
                .padding(.top, PlatformMetrics.hairlineSpacing)
                .padding(.bottom, PlatformMetrics.formRowVerticalPadding)

                if canExpandMembers || !allMemberTargets.isEmpty {
                    Button {
                        if canExpandMembers, !showAllMembers {
                            PlatformMotion.withAnimation(.snappy) { showAllMembers = true }
                        } else {
                            showMemberList = true
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(
                                canExpandMembers && !showAllMembers
                                    ? BuddyMemberCopy.moreMembers
                                    : BuddyMemberCopy.viewAllMembers
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            Image(systemName: canExpandMembers && !showAllMembers ? "chevron.down" : "list.bullet")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(BuddyMemberCopy.viewAllMembers)

                    if showAllMembers, canExpandMembers {
                        Button {
                            PlatformMotion.withAnimation(.snappy) { showAllMembers = false }
                        } label: {
                            HStack {
                                Spacer()
                                Text(BuddyMemberCopy.collapseMembers)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selfMemberCell: some View {
        let alias = prefs.myGroupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = GroupNicknameDisplay.formatted(
            realName: app.user.name,
            groupAlias: alias.isEmpty ? nil : alias
        )
        let caption = prefs.showMemberNicknames ? truncated(display) : String(display.prefix(1))
        if let target = memberProfileTarget(forSelf: true) {
            CircleMemberNavigationLink(
                item: target.item,
                source: target.source,
                groupAlias: target.groupAlias
            ) {
                memberAvatarStack(
                    displayName: target.profileDisplayName,
                    caption: caption,
                    accessibilityRole: BuddyMemberCopy.roleSelf
                )
            }
        } else {
            memberAvatarStack(
                displayName: display,
                caption: caption,
                accessibilityRole: BuddyMemberCopy.roleSelf
            )
        }
    }

    @ViewBuilder
    private func memberCell(_ member: GroupMemberRecord) -> some View {
        let alias = model.groupAlias(for: member.nickname, in: conversationID)
        let display = GroupNicknameDisplay.formatted(realName: member.nickname, groupAlias: alias)
        let caption = prefs.showMemberNicknames ? truncated(display) : String(display.prefix(1))
        if let target = memberProfileTarget(for: member) {
            CircleMemberNavigationLink(
                item: target.item,
                source: target.source,
                groupAlias: target.groupAlias
            ) {
                memberAvatarStack(
                    displayName: target.profileDisplayName,
                    caption: caption,
                    accessibilityRole: target.role
                )
            }
        } else {
            memberAvatarStack(
                displayName: display,
                caption: caption,
                accessibilityRole: roleLabel(member.role)
            )
        }
    }

    private var addMemberCell: some View {
        Button {
            showInviteSheet = true
        } label: {
            VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous)
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                Text(BuddyOrgJoinCopy.inviteMember)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BuddyOrgJoinCopy.inviteMemberA11y)
    }

    private func memberAvatarStack(
        displayName: String,
        caption: String,
        accessibilityRole: String
    ) -> some View {
        VStack(spacing: PlatformMetrics.detailMicroSpacing) {
            PlatformListAvatarView(name: displayName, side: 52)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 56)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(accessibilityRole)，\(displayName)")
        .accessibilityHint(BuddyMemberCopy.profileTitle)
    }

    private func memberProfileTarget(for member: GroupMemberRecord) -> BuddyMemberProfileTarget? {
        let item = buddies.discoverItem(
            for: member.nickname,
            fallbackCircleName: conversation?.title ?? member.nickname
        )
        return BuddyMemberProfileTarget(
            item: item,
            source: profileSource,
            role: roleLabel(member.role),
            groupAlias: model.groupAlias(for: member.nickname, in: conversationID)
        )
    }

    private func memberProfileTarget(forSelf: Bool) -> BuddyMemberProfileTarget? {
        guard forSelf else { return nil }
        let name = app.user.name
        let item = buddies.discoverItem(
            for: name,
            fallbackCircleName: conversation?.title ?? name
        )
        return BuddyMemberProfileTarget(
            item: item,
            source: profileSource,
            role: BuddyMemberCopy.roleSelf,
            groupAlias: model.groupAlias(for: name, in: conversationID)
        )
    }

    private func roleLabel(_ role: GroupMemberRole) -> String {
        switch role {
        case .owner: GroupMemberRole.owner.rawValue
        case .admin: GroupMemberRole.admin.rawValue
        case .member: BuddyMemberCopy.roleMember
        }
    }

    private func truncated(_ name: String) -> String {
        if name.count <= 4 { return name }
        return String(name.prefix(3)) + "…"
    }
}
