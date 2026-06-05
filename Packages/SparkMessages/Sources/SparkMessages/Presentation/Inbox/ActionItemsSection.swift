// Module: SparkMessages — Action-required cards at top of inbox.

import SwiftUI

struct ActionItemsSection: View {
    let items: [ActionItem]
    var onInviteAccept: (ActivityInvite) -> Void
    var onInviteDecline: (ActivityInvite) -> Void
    var onOpenActivity: (String) -> Void
    var onDismiss: (ActionItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if items.isEmpty {
                emptyState
            } else {
                ForEach(items) { item in
                    actionCard(for: item)
                }
            }
        }
        .padding(.bottom, 8)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .background(.thinMaterial)
    }

    private var header: some View {
        HStack {
            Label(
                String(localized: "messages.action.section", defaultValue: "即将行动", comment: "Action section"),
                systemImage: "bolt.fill"
            )
            .font(.subheadline.weight(.semibold))
            Spacer()
            if !items.isEmpty {
                Text("\(items.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var emptyState: some View {
        Text(
            String(
                localized: "messages.action.empty",
                defaultValue: "没有待处理事项",
                comment: "No pending actions"
            )
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func actionCard(for item: ActionItem) -> some View {
        switch item.kind {
        case .activityInvite(let invite):
            ActivityInviteActionCard(
                invite: invite,
                onAccept: { onInviteAccept(invite) },
                onDecline: { onInviteDecline(invite) }
            )
        case .activityChanged(let change):
            ActivityChangeAlertCard(
                change: change,
                onViewActivity: { onOpenActivity(change.activity.id) },
                onDismiss: { onDismiss(item) }
            )
        case .waitlistPromoted(let activity):
            WaitlistPromotedCard(
                activity: activity,
                onViewActivity: { onOpenActivity(activity.id) },
                onDismiss: { onDismiss(item) }
            )
        }
    }
}
