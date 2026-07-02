// Module: SparkCommunity — Shared like affordance for feed and detail.

import SparkDesignSystem
import SwiftUI

struct CommunityPostLikeControl: View {
    let isLiked: Bool
    let likeCount: Int
    let isPending: Bool
    let onToggle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var likeScale: CGFloat = 1

    var body: some View {
        Button {
            guard !isPending else { return }
            if reduceMotion {
                onToggle()
            } else {
                withAnimation(.spring(response: 0.3)) {
                    likeScale = 1.25
                    onToggle()
                }
                withAnimation(.spring(response: 0.3).delay(0.12)) {
                    likeScale = 1
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? .pink : .primary)
                if likeCount > 0 {
                    Text("\(likeCount)")
                        .foregroundStyle(.secondary)
                }
            }
            .scaleEffect(likeScale)
        }
        .buttonStyle(.plain)
        .sparkMinimumTouchTarget()
        .disabled(isPending)
        .accessibilityLabel(
            String(localized: "community.post.like.a11y", defaultValue: "点赞", comment: "Like")
        )
        .accessibilityValue(
            isLiked
                ? String(localized: "community.post.like.on", defaultValue: "已赞", comment: "Liked state")
                : String(localized: "community.post.like.off", defaultValue: "未赞", comment: "Not liked state")
        )
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Like control") {
        HStack(spacing: 20) {
            CommunityPostLikeControl(isLiked: false, likeCount: 3, isPending: false, onToggle: {})
            CommunityPostLikeControl(isLiked: true, likeCount: 12, isPending: false, onToggle: {})
        }
        .font(.subheadline)
        .padding()
    }
}
