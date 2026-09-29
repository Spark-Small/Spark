//
//  BuddyMemberListSheet.swift
//  坐标系
//
//  圈子 / 工会「查看全部成员」：系统 List + browser detent。
//

import SwiftUI
import CoordinateModels

struct BuddyMemberListSheet: View {
    let title: String
    let members: [BuddyMemberProfileTarget]
    var onBook: ((PaidCompanion) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var navigation = TabNavigationState()

    var body: some View {
        @Bindable var navigation = navigation

        NavigationStack(path: $navigation.path) {
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
                            CircleMemberNavigationLink(
                                item: member.item,
                                source: member.source,
                                groupAlias: member.groupAlias
                            ) {
                                memberRow(member)
                            }
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
            .circleMemberSheetNavigationDestination()
        }
        .tabNavigationState(navigation)
        .independentNavigationSheetChrome()
        .platformSheet(.browser)
    }

    private func memberRow(_ member: BuddyMemberProfileTarget) -> some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformListAvatarView(name: member.item.profile.nickname)

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(member.profileDisplayName)
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
