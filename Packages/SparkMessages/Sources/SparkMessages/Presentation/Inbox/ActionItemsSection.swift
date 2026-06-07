// Module: SparkMessages — Activity request cards embedded in Activity tab List.

import SparkDesignSystem
import SwiftUI

/// Request cards for the **活动请求** inbox segment (invites, changes, waitlist).
public struct InboxActionItemsListSection: View {
    let items: [ActionItem]
    var showsSectionHeader: Bool
    var onInviteAccept: (ActivityInvite) -> Void
    var onInviteDecline: (ActivityInvite) -> Void
    var onOpenActivity: (String) -> Void
    var onDismiss: (ActionItem) -> Void

    public init(
        items: [ActionItem],
        showsSectionHeader: Bool = false,
        onInviteAccept: @escaping (ActivityInvite) -> Void,
        onInviteDecline: @escaping (ActivityInvite) -> Void,
        onOpenActivity: @escaping (String) -> Void,
        onDismiss: @escaping (ActionItem) -> Void
    ) {
        self.items = items
        self.showsSectionHeader = showsSectionHeader
        self.onInviteAccept = onInviteAccept
        self.onInviteDecline = onInviteDecline
        self.onOpenActivity = onOpenActivity
        self.onDismiss = onDismiss
    }

    public var body: some View {
        if showsSectionHeader {
            Section {
                requestRows
            } header: {
                sectionHeader
            }
        } else {
            Section {
                requestRows
            }
        }
    }

    private var requestRows: some View {
        ForEach(items) { item in
            actionCard(for: item)
                .sparkFlatTabListRow()
        }
    }

    private var sectionHeader: some View {
        HStack {
            Label(
                String(
                    localized: "activity.requests.section",
                    defaultValue: "活动请求",
                    comment: "Activity requests section"
                ),
                systemImage: "tray.full"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            Spacer()
            Text("\(items.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .accessibilityLabel(sectionAccessibilityLabel)
    }

    private var sectionAccessibilityLabel: String {
        let format = String(
            localized: "activity.requests.section.a11y.format",
            defaultValue: "活动请求，%1$d 项",
            comment: "Activity requests section; item count"
        )
        return String(format: format, locale: .current, items.count)
    }

    @ViewBuilder
    private func actionCard(for item: ActionItem) -> some View {
        Group {
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDismiss(item)
            } label: {
                Label(
                    String(localized: "messages.action.dismiss", defaultValue: "移除", comment: "Dismiss action item"),
                    systemImage: "trash"
                )
            }
        }
    }
}

#Preview("Activity requests — embedded") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 2)
    List {
        InboxActionItemsListSection(
            items: inbox.actionItems,
            onInviteAccept: { _ in },
            onInviteDecline: { _ in },
            onOpenActivity: { _ in },
            onDismiss: { _ in }
        )
        Section {
            Text("Activity row")
        }
    }
    .sparkFlatTabListStyle()
}
