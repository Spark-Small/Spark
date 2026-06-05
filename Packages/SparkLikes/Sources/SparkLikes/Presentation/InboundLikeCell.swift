// Module: SparkLikes — Two-column inbound grid cell.

import SparkCore
import SwiftUI

struct InboundLikeCell: View {
    let item: InboundLikeItem
    let isBlurred: Bool
    var onLikeBack: () -> Void
    var onUnlock: () -> Void

    var body: some View {
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
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isBlurred {
                onUnlock()
            } else {
                onLikeBack()
            }
        }
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
                Rectangle()
                    .fill(.thickMaterial)
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
        .background(.ultraThinMaterial)
    }

    private var blurredName: String {
        String(localized: "likes.inbound.blur.name", defaultValue: "••••", comment: "Blurred name")
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
                media: DiscoverMedia(kind: .image, url: URL(string: "https://example.com/a.jpg")!)
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
