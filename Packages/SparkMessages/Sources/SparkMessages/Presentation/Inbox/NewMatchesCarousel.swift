// Module: SparkMessages — Horizontal new-match avatars for icebreaking.

import SparkDesignSystem
import SwiftUI

struct NewMatchesCarousel: View {
    let matches: [MatchPreview]
    var onSelect: (MatchPreview) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                String(
                    localized: "messages.matches.new",
                    defaultValue: "新配对",
                    comment: "New matches carousel title"
                )
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SparkLayoutMetrics.standardHorizontalPadding) {
                    ForEach(matches) { match in
                        Button {
                            onSelect(match)
                        } label: {
                            NewMatchAvatar(match: match)
                        }
                        .buttonStyle(.sparkPressable)
                    }
                }
                .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            }
        }
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}

private struct NewMatchAvatar: View {
    let match: MatchPreview

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .frame(
                    width: SparkLayoutMetrics.newMatchAvatarOuter,
                    height: SparkLayoutMetrics.newMatchAvatarOuter
                )
            avatar
                .frame(
                    width: SparkLayoutMetrics.newMatchAvatarInner,
                    height: SparkLayoutMetrics.newMatchAvatarInner
                )
                .clipShape(Circle())
            Circle()
                .fill(Color(.systemRed))
                .frame(
                    width: SparkLayoutMetrics.newMatchUnreadDotSize,
                    height: SparkLayoutMetrics.newMatchUnreadDotSize
                )
                .offset(x: 24, y: -24)
            }
            Text(match.user.displayName)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 72)
        }
        .accessibilityLabel(match.user.displayName)
        .accessibilityHint(
            String(
                localized: "messages.matches.tap.hint",
                defaultValue: "开始聊天",
                comment: "Tap to start chat"
            )
        )
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = match.user.avatarURL {
            SparkCachedRemoteImage(
                url: url,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    placeholder
                }
            )
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.accentColor)
    }
}

#Preview("New matches carousel") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 0)
    List {
        NewMatchesCarousel(matches: inbox.unmessagedMatches, onSelect: { _ in })
    }
    .listStyle(.plain)
}
