// Module: SparkCommunity — Community member list sheet.

import SparkDesignSystem
import SwiftUI

struct CommunityMembersSheet: View {
    let members: [CommunityMember]
    let onSelectMember: (CommunityMember) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(members) { member in
                Button {
                    dismiss()
                    onSelectMember(member)
                } label: {
                    MemberRow(member: member)
                }
                .buttonStyle(.sparkPressable)
            }
            .navigationTitle(
                String(localized: "community.members.title", defaultValue: "成员", comment: "Members title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        String(localized: "community.members.close", defaultValue: "关闭", comment: "Close members")
                    ) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MemberRow: View {
    let member: CommunityMember

    var body: some View {
        HStack(spacing: 12) {
            memberAvatar
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                if !member.bio.isEmpty {
                    Text(member.bio)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                RelationshipBadge(context: member.relationship)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(member.displayName)
    }

    @ViewBuilder
    private var memberAvatar: some View {
        if let url = member.avatarURL {
            SparkCachedRemoteImage(
                url: url,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    Color(.tertiarySystemFill)
                }
            )
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Members sheet") {
        CommunityMembersSheet(
            members: [
                CommunityMember(
                    id: "m1",
                    displayName: String(localized: "community.mock.1.author", defaultValue: "阿乐", comment: "Author"),
                    bio: String(localized: "community.mock.member.bio.1", defaultValue: "周末爬山", comment: "Bio")
                ),
                CommunityMember(
                    id: "m2",
                    displayName: String(localized: "community.mock.3.author", defaultValue: "Nova", comment: "Author")
                )
            ],
            onSelectMember: { _ in }
        )
    }
}
