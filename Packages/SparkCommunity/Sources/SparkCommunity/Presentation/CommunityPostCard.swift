// Module: SparkCommunity — Instagram-style feed post card.

import SparkDesignSystem
import SwiftUI

struct CommunityPostCard: View {
    let post: CommunityFeedPost
    let isLiked: Bool
    let likeCount: Int
    let onToggleLike: () -> Void
    let onOpen: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isExpanded = false
    @State private var likeScale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            authorRow
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Button(action: onOpen) {
                mediaRegion
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(localized: "community.post.open.a11y", defaultValue: "查看帖子", comment: "Open post")
            )

            actionRow
                .padding(.horizontal, 16)
                .padding(.top, 10)

            contentRegion
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(.background)
        Divider()
    }

    private var authorRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(String(post.authorDisplayName.prefix(1)))
                    .font(.caption.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .sparkGlassControl(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorDisplayName)
                        .font(.subheadline.weight(.semibold))
                    Text(post.communityName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            if let shared = post.sharedActivityWithViewer {
                Text(
                    String(
                        format: String(
                            localized: "community.post.sharedActivity",
                            defaultValue: "和你去了 %@",
                            comment: "Shared activity; %@ is name"
                        ),
                        locale: .current,
                        shared.name
                    )
                )
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            } else if post.relationshipToViewer != .none {
                RelationshipBadge(context: post.relationshipToViewer)
            }
        }
    }

    @ViewBuilder
    private var mediaRegion: some View {
        if let imageURL = post.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16 / 9, contentMode: .fill)
                default:
                    Color(.systemGray6)
                        .aspectRatio(16 / 9, contentMode: .fill)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
        } else {
            TextOnlyPostBackground(text: post.content)
                .frame(height: 180)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 16) {
            Button {
                if reduceMotion {
                    onToggleLike()
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        likeScale = 1.4
                        onToggleLike()
                    }
                    withAnimation(.spring(response: 0.3).delay(0.12)) {
                        likeScale = 1
                    }
                }
            } label: {
                Label("\(likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(isLiked ? .pink : .primary)
                    .scaleEffect(likeScale)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(localized: "community.post.like.a11y", defaultValue: "点赞", comment: "Like")
            )

            Label("\(post.commentCount)", systemImage: "bubble.right")
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
            Image(systemName: "square.and.arrow.up")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .font(.subheadline)
    }

    private var contentRegion: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(attributedContent)
                .font(.subheadline)
                .lineLimit(isExpanded ? nil : 2)
            if !isExpanded, post.content.count > 80 {
                Button(
                    String(localized: "community.post.readMore", defaultValue: "更多", comment: "Read more")
                ) {
                    isExpanded = true
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if !post.tags.isEmpty {
                Text(post.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(relativeTime)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var attributedContent: AttributedString {
        var line = AttributedString(post.authorDisplayName)
        line.font = .subheadline.weight(.semibold)
        let body = AttributedString(" \(post.content)")
        return line + body
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
}

private struct TextOnlyPostBackground: View {
    let text: String

    private var paletteIndex: Int {
        abs(text.hashValue) % 4
    }

    var body: some View {
        ZStack {
            backgroundColor
            Text(text)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(24)
        }
    }

    private var backgroundColor: Color {
        switch paletteIndex {
        case 0: Color(.systemTeal).opacity(0.15)
        case 1: Color(.systemIndigo).opacity(0.12)
        case 2: Color(.systemOrange).opacity(0.12)
        default: Color(.systemGray6)
        }
    }
}
