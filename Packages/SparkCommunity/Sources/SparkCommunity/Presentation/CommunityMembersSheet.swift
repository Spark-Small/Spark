// Module: SparkCommunity — Community member list sheet.

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
                .buttonStyle(.plain)
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
    }

    @ViewBuilder
    private var memberAvatar: some View {
        if let url = member.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Circle().fill(.thinMaterial)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(.thinMaterial)
                .frame(width: 44, height: 44)
        }
    }
}
