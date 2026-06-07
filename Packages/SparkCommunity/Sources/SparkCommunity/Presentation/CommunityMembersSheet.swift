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
                    .font(.body.weight(.medium))
                if !member.bio.isEmpty {
                    Text(member.bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
    CommunityMembersSheet(
        members: [
            CommunityMember(id: "m1", displayName: "Alex", bio: "Runner"),
            CommunityMember(id: "m2", displayName: "Nova")
        ],
        onSelectMember: { _ in }
    )
}
