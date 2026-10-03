//
//  BuddyOrgInfoScaffold+Members.swift
//  坐标系
//
//  组织资料：成员网格与元数据。
//

import SwiftUI
import CoordinateModels

extension BuddyOrgInfoScaffold {
    // MARK: - Members

    var memberSection: some View {
        Section {
            if members.isEmpty && !isJoined {
                ContentUnavailableView {
                    Label(BuddyMemberCopy.emptyMembersTitle, systemImage: "person.2")
                } description: {
                    Text(BuddyMemberCopy.emptyMembersDescription)
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, PlatformMetrics.minContentGap)
            } else if members.isEmpty && isJoined {
                ContentUnavailableView {
                    Label(BuddyMemberCopy.emptyMembersTitle, systemImage: "person.2")
                } description: {
                    Text(BuddyMemberCopy.emptyMembersDescription)
                } actions: {
                    Button(BuddyMemberCopy.emptyMembersInviteCTA, action: onInviteTap)
                        .activityPrimaryCTA(controlSize: .regular)
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, PlatformMetrics.minContentGap)
            } else {
                LazyVGrid(columns: columns, spacing: PlatformMetrics.cardInfoSpacing) {
                    if isJoined {
                        selfMemberCell
                    }
                    ForEach(Array(visibleMembers.enumerated()), id: \.element.id) { offset, member in
                        memberCell(member, index: offset)
                    }
                    if isJoined {
                        addMemberCell
                    }
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

    var myGroupNicknameLabel: String {
        GroupNicknameDisplay.settingsValue(
            realName: app.user.name,
            myGroupNickname: prefs.myGroupNickname
        )
    }

    @ViewBuilder
    var groupNicknameLink: some View {
        NavigationLink {
            GroupNicknameEditView(
                realName: app.user.name,
                initial: myGroupNicknameLabel
            ) { saved in
                var next = prefs
                next.myGroupNickname = saved
                onPrefsChange(next)
                if let id = circleConversationID {
                    messages.setGroupAlias(saved, forMember: app.user.name, in: id)
                }
            }
        } label: {
            LabeledContent(nicknameFieldTitle, value: myGroupNicknameLabel)
        }
    }

    @ViewBuilder
    var selfMemberCell: some View {
        let alias = prefs.myGroupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = GroupNicknameDisplay.formatted(
            realName: app.user.name,
            groupAlias: alias.isEmpty ? nil : alias
        )
        let caption = prefs.showMemberNicknames ? truncated(display) : String(display.prefix(1))
        if let target = selfMemberTarget {
            CircleMemberNavigationLink(
                item: target.item,
                source: target.source,
                groupAlias: target.groupAlias
            ) {
                selfMemberAvatarStack(
                    displayName: target.profileDisplayName,
                    caption: caption,
                    accessibilityRole: target.role
                )
            }
        } else {
            selfMemberAvatarStack(
                displayName: display,
                caption: caption,
                accessibilityRole: BuddyMemberCopy.roleSelf
            )
        }
    }

    func selfMemberAvatarStack(
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
    }

    @ViewBuilder
    func memberCell(_ member: Member, index: Int) -> some View {
        let name = memberName(member)
        let label = prefs.showMemberNicknames ? truncated(name) : String(name.prefix(1))
        if let target = memberTarget(member, index) {
            CircleMemberNavigationLink(
                item: target.item,
                source: target.source,
                groupAlias: target.groupAlias
            ) {
                let display = target.profileDisplayName
                let label = prefs.showMemberNicknames ? truncated(display) : String(display.prefix(1))
                memberAvatarStack(displayName: display, label: label, role: target.role)
            }
        } else {
            memberAvatarStack(displayName: name, label: label, role: nil)
        }
    }

    func memberAvatarStack(displayName: String, label: String, role: String?) -> some View {
        VStack(spacing: PlatformMetrics.detailMicroSpacing) {
            PlatformListAvatarView(name: displayName, side: 52)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 56)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(
            role.map { BuddyMemberCopy.listAccessibility(nickname: displayName, role: $0) }
                ?? displayName
        )
        .accessibilityHint(BuddyMemberCopy.profileTitle)
    }

    var addMemberCell: some View {
        Button(action: onInviteTap) {
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

    // MARK: - Metadata

    var metadataSection: some View {
        Section {
            LabeledContent(nameLabel, value: displayName)
            LabeledContent(BuddyOrgJoinCopy.cityRow, value: cityLine)
            ForEach(metaRows, id: \.title) { row in
                LabeledContent(row.title, value: row.value)
            }

            HStack {
                Text(CircleGroupCopy.qrCode)
                Spacer()
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(CircleGroupCopy.qrCode)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(CircleGroupCopy.announcement)
                Text(announcement)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(.vertical, PlatformMetrics.hairlineSpacing)
        }
    }

    func truncated(_ name: String) -> String {
        if name.count <= 4 { return name }
        return String(name.prefix(3)) + "…"
    }
}
