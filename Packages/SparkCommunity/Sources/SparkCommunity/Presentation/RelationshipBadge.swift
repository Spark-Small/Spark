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
            .font(.caption2)
            .foregroundStyle(.orange)
        case .matched:
            Label(
                String(localized: "community.relationship.matched", defaultValue: "已配对", comment: "Matched"),
                systemImage: "heart.fill"
            )
            .font(.caption2)
            .foregroundStyle(.pink)
        case .liked:
            Label(
                String(localized: "community.relationship.liked", defaultValue: "你喜欢过 TA", comment: "Liked"),
                systemImage: "heart"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        case .none:
            EmptyView()
        }
    }
}
