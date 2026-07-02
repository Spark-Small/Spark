// Module: SparkCommunity — Lightweight profile from community context.

import SparkDesignSystem
import SwiftUI

struct CommunityMemberProfileSheet: View {
    let profile: CommunityProfilePreview
    let isLiked: Bool
    let onLike: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
        SparkUnifiedIdentityContent(
            model: identityModel
        ) {
            primaryAction
        }
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

    private var identityModel: SparkUnifiedIdentityModel {
        SparkUnifiedIdentityModel(
            id: profile.id,
            displayName: profile.displayName,
            avatarURL: profile.avatarURL,
            bio: profile.bio,
            relationshipLabel: relationshipLabel
        )
    }

    private var relationshipLabel: String? {
        switch profile.relationship {
        case .sharedActivity(let name):
            String(
                format: String(
                    localized: "community.relationship.sharedActivity",
                    defaultValue: "也去了 %@",
                    comment: "Shared activity; %@ is name"
                ),
                locale: .current,
                name
            )
        case .matched:
            String(localized: "community.relationship.matched", defaultValue: "已配对", comment: "Matched")
        case .liked:
            String(localized: "community.relationship.liked", defaultValue: "你喜欢过 TA", comment: "Liked")
        case .attendedLinkedActivity:
            String(
                localized: "community.relationship.attendedLinkedActivity",
                defaultValue: "已参加",
                comment: "Attended linked activity badge"
            )
        case .none:
            nil
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
        case .liked, .sharedActivity, .attendedLinkedActivity, .none:
            Button(action: onLike) {
                Text(
                    isLiked
                        ? String(localized: "community.profile.liked", defaultValue: "你已表达喜欢", comment: "Already liked")
                        : String(localized: "community.profile.like", defaultValue: "喜欢", comment: "Like person")
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLiked || profile.relationship == .liked)
        }
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Member profile sheet") {
        CommunityMemberProfileSheet(
            profile: CommunityProfilePreview(
                person: DiscoveredPerson(
                    id: "u1",
                    displayName: String(localized: "community.mock.1.author", defaultValue: "阿乐", comment: "Author"),
                    avatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u1"),
                    sharedTag: String(localized: "community.mock.tag.hike", defaultValue: "爬山", comment: "Tag"),
                    relationship: .none
                )
            ),
            isLiked: false,
            onLike: {}
        )
    }
}
