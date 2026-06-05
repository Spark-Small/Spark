// Module: SparkCommunity — Lightweight profile from community context.

import SwiftUI

struct CommunityMemberProfileSheet: View {
    let profile: CommunityProfilePreview
    let isLiked: Bool
    let onLike: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                avatar
                Text(profile.displayName)
                    .font(.title2.weight(.semibold))
                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                RelationshipBadge(context: profile.relationship)
                Spacer(minLength: 0)
                primaryAction
            }
            .padding()
            .navigationTitle(
                String(localized: "community.profile.title", defaultValue: "资料", comment: "Profile title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        String(localized: "community.profile.close", defaultValue: "关闭", comment: "Close profile")
                    ) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = profile.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Circle().fill(.regularMaterial)
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 88, height: 88)
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch profile.relationship {
        case .matched:
            Text(
                String(
                    localized: "community.profile.matched",
                    defaultValue: "你们已配对，去消息页聊聊吧",
                    comment: "Matched hint"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        default:
            Button(action: onLike) {
                Label(
                    isLiked
                        ? String(localized: "community.profile.liked", defaultValue: "已喜欢", comment: "Liked")
                        : String(localized: "community.profile.like", defaultValue: "喜欢 TA", comment: "Like person"),
                    systemImage: isLiked ? "checkmark.circle.fill" : "heart.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLiked)
        }
    }
}
