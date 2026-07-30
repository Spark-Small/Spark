//
//  BuddyMemberListSheet.swift
//  坐标系
//
//  组织 / 工会「查看全部成员」：系统 List + browser detent。
//

import SwiftUI

struct BuddyMemberListSheet: View {
    let title: String
    let members: [BuddyMemberProfileTarget]
    var onMessage: (DiscoverBuddyItem) -> Void
    var onBook: ((PaidCompanion) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selected: BuddyMemberProfileTarget?

    var body: some View {
        NavigationStack {
            List {
                if members.isEmpty {
                    ContentUnavailableView(
                        BuddyMemberCopy.emptyMembersTitle,
                        systemImage: "person.2",
                        description: Text(BuddyMemberCopy.emptyMembersDescription)
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(members) { member in
                            Button {
                                selected = member
                            } label: {
                                memberRow(member)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(BuddyMemberCopy.memberCount(members.count))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyMemberCopy.done) { dismiss() }
                }
            }
            .sheet(item: $selected) { target in
                BuddyMemberProfileSheet(
                    target: target,
                    onMessage: onMessage,
                    onBook: onBook
                )
            }
        }
        .platformSheet(.browser)
    }

    private func memberRow(_ member: BuddyMemberProfileTarget) -> some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformListAvatarView(name: member.item.profile.nickname)

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(member.item.profile.nickname)
                    .font(PlatformListTypography.primary)
                    .foregroundStyle(.primary)
                Text(member.role)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if case .paid(let companion) = member.item {
                Text(companion.priceText)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(PlatformStatus.warning)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            BuddyMemberCopy.listAccessibility(
                nickname: member.item.profile.nickname,
                role: member.role
            )
        )
        .accessibilityHint(BuddyMemberCopy.profileTitle)
    }
}
