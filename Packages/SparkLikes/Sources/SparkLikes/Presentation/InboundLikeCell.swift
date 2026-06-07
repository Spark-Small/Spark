// Module: SparkLikes — Two-column inbound grid cell.

import SparkCore
import SparkDesignSystem
import SwiftUI

struct InboundLikeCell: View {
    let item: InboundLikeItem
    let isBlurred: Bool
    var onLikeBack: () -> Void
    var onUnlock: () -> Void

    var body: some View {
        Button {
            if isBlurred {
                onUnlock()
            } else {
                onLikeBack()
            }
        } label: {
            VStack(spacing: 0) {
                media
                    .frame(height: 140)
                    .clipped()
                infoBar
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                if item.intensity == .spark, !isBlurred {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.yellow.gradient, lineWidth: 2)
                }
            }
            .overlay(alignment: .topTrailing) {
                if item.intensity == .spark, !isBlurred {
                    Image(systemName: "bolt.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.yellow)
                        .padding(6)
                        .sparkGlassControl(Circle())
                        .padding(8)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.sparkPressable)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    @ViewBuilder
    private var media: some View {
        if isBlurred {
            ZStack {
                DiscoverCardMediaView(
                    card: item.card,
                    isActive: false,
                    zoomState: DiscoverPhotoZoomState()
                )
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
                Color.primary.opacity(0.12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        } else {
            DiscoverCardMediaView(
                card: item.card,
                isActive: true,
                zoomState: DiscoverPhotoZoomState()
            )
        }
    }

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isBlurred ? blurredName : item.card.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            if let opener = item.opener, !opener.isEmpty, !isBlurred {
                Text(opener)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else if item.intensity == .spark, !isBlurred {
                Text(
                    String(
                        localized: "likes.inbound.spark.label",
                        defaultValue: "心动了你",
                        comment: "Inbound spark label"
                    )
                )
                .font(.caption)
                .foregroundStyle(.yellow)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private var blurredName: String {
        String(localized: "likes.inbound.blur.name", defaultValue: "••••", comment: "Blurred name")
    }

    private var accessibilityLabel: String {
        if isBlurred {
            return String(
                localized: "likes.inbound.unlock.a11y",
                defaultValue: "解锁查看喜欢你的人",
                comment: "Unlock inbound like"
            )
        }
        if let opener = item.opener, !opener.isEmpty {
            let format = String(
                localized: "likes.inbound.likeBack.opener.format",
                defaultValue: "%@，开场白：%@",
                comment: "Inbound like back; %1$@ name, %2$@ opener"
            )
            return String(format: format, locale: .current, item.card.displayName, opener)
        }
        if item.intensity == .spark {
            let format = String(
                localized: "likes.inbound.likeBack.spark.format",
                defaultValue: "%@ 心动了你，回喜欢",
                comment: "Inbound spark; %@ is name"
            )
            return String(format: format, locale: .current, item.card.displayName)
        }
        let format = String(
            localized: "likes.inbound.likeBack.format",
            defaultValue: "%@ 喜欢了你，回喜欢",
            comment: "Inbound like; %@ is name"
        )
        return String(format: format, locale: .current, item.card.displayName)
    }

    private var accessibilityHint: String {
        if isBlurred {
            return String(
                localized: "likes.inbound.unlock.hint",
                defaultValue: "双击解锁并查看资料",
                comment: "Unlock hint"
            )
        }
        return String(
            localized: "likes.inbound.likeBack.hint",
            defaultValue: "双击回喜欢",
            comment: "Like back hint"
        )
    }
}

#Preview {
    InboundLikeCell(
        item: InboundLikeItem(
            userID: UserID("u1"),
            card: DiscoverCard(
                userID: UserID("u1"),
                displayName: "Preview",
                bio: "",
                gender: nil,
                media: DiscoverMedia(kind: .image, url: MockURL.require("https://example.com/a.jpg"))
            ),
            intensity: .spark,
            opener: "你好"
        ),
        isBlurred: false,
        onLikeBack: {},
        onUnlock: {}
    )
    .frame(width: 160)
    .padding()
}
