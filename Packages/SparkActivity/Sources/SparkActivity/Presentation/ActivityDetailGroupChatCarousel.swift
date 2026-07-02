// Module: SparkActivity — Horizontal group chat tiles (name above icon).

import SparkDesignSystem
import SwiftUI

struct ActivityDetailGroupChatCarousel: View {
    let entries: [ActivityGroupChatEntry]
    let hasAccess: Bool
    let onOpenChat: (ActivityGroupChatEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            sectionHeader

            if entries.isEmpty {
                emptyState
            } else if hasAccess {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                        ForEach(entries) { entry in
                            Button {
                                onOpenChat(entry)
                            } label: {
                                groupChatTile(entry: entry)
                            }
                            .buttonStyle(.sparkPressable)
                        }
                    }
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                }
            } else {
                lockedState
            }
        }
    }

    private var sectionHeader: some View {
        Text(
            String(
                localized: "activity.detail.groupChats.section",
                defaultValue: "活动群聊",
                comment: "Group chats section"
            )
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.sectionTopPadding)
        .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
        .accessibilityAddTraits(.isHeader)
    }

    private func groupChatTile(entry: ActivityGroupChatEntry) -> some View {
        VStack(spacing: 8) {
            Text(entry.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 88)

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 56, height: 56)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(width: 96)
        .accessibilityLabel(entry.displayName)
        .accessibilityHint(
            String(
                localized: "activity.detail.groupChat.open.hint",
                defaultValue: "进入群聊",
                comment: "Open group chat hint"
            )
        )
    }

    private var emptyState: some View {
        Text(
            String(
                localized: "activity.detail.groupChats.empty",
                defaultValue: "暂无群聊",
                comment: "No group chats"
            )
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
    }

    private var lockedState: some View {
        Text(
            String(
                localized: "activity.detail.discussion.locked.footer",
                defaultValue: "使用底部「参加」报名后，即可进入活动群聊。",
                comment: "Discussion locked footer"
            )
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
    }
}

#Preview {
    ActivityDetailGroupChatCarousel(
        entries: [
            ActivityGroupChatEntry(id: "t1", threadID: "t1", displayName: "周末徒步群"),
            ActivityGroupChatEntry(id: "t2", threadID: "t2", displayName: "集合讨论")
        ],
        hasAccess: true,
        onOpenChat: { _ in }
    )
}
