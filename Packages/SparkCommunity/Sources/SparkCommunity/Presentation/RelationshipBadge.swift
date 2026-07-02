// Module: SparkCommunity — Relationship context chip.

import SwiftUI

struct RelationshipBadge: View {
    let context: RelationshipContext

    var body: some View {
        switch context {
        case .sharedActivity(let name):
            Label(
                String(
                    format: String(
                        localized: "community.relationship.sharedActivity",
                        defaultValue: "也去了 %@",
                        comment: "Shared activity; %@ is name"
                    ),
                    locale: .current,
                    name
                ),
                systemImage: "figure.hiking"
            )
            .font(.footnote)
            .foregroundStyle(Color.accentColor)
        case .attendedLinkedActivity:
            Label(
                String(
                    localized: "community.relationship.attendedLinkedActivity",
                    defaultValue: "已参加",
                    comment: "Attended linked activity badge"
                ),
                systemImage: "checkmark.circle.fill"
            )
            .font(.footnote)
            .foregroundStyle(Color.accentColor)
        case .matched:
            Label(
                String(localized: "community.relationship.matched", defaultValue: "已配对", comment: "Matched"),
                systemImage: "heart.fill"
            )
            .font(.footnote)
            .foregroundStyle(.pink)
        case .liked:
            Label(
                String(localized: "community.relationship.liked", defaultValue: "你喜欢过 TA", comment: "Liked"),
                systemImage: "heart"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        case .none:
            EmptyView()
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Relationship badge") {
        VStack(spacing: 8) {
            RelationshipBadge(context: .matched)
            RelationshipBadge(context: .liked)
            RelationshipBadge(
                context: .sharedActivity(
                    String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity")
                )
            )
            RelationshipBadge(context: .attendedLinkedActivity)
        }
        .padding()
    }
}
