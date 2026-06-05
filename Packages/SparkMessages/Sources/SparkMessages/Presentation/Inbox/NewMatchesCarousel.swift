// Module: SparkMessages — Horizontal new-match avatars for icebreaking.

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
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(matches) { match in
                        Button {
                            onSelect(match)
                        } label: {
                            NewMatchAvatar(match: match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
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
                    .frame(width: 64, height: 64)
                avatar
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
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
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    placeholder
                }
            }
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
