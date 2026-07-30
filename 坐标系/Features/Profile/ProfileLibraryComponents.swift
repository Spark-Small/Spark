//
//  ProfileLibraryComponents.swift
//  坐标系
//
//  「我的」一级页内容预览组件：发布媒体行、竖海报。
//

import SwiftUI

struct ProfilePublishedLibraryLabel<Media: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var media: () -> Media

    var body: some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            stackedThumbnail

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var stackedThumbnail: some View {
        Color.clear
            .aspectRatio(PlatformMetrics.activityCardAspectRatio, contentMode: .fit)
            .overlay { media() }
            .clipShape(PlatformMetrics.mediaShape)
            .background {
                PlatformMetrics.mediaShape
                    .fill(.tertiary)
                    .padding(.horizontal, PlatformMetrics.captionBadgeInset)
                    .offset(y: -PlatformMetrics.captionBadgeInset)
            }
            .padding(.top, PlatformMetrics.captionBadgeInset)
            .platformProfileMediaLibraryThumbnailFrame()
    }
}

struct ProfileLibraryShelfCard<Media: View>: View {
    let title: String
    let subtitle: String
    var badge: String? = nil
    @ViewBuilder var media: () -> Media

    var body: some View {
        ZStack {
            Color.clear
                .aspectRatio(PlatformMetrics.profileLibraryCardAspectRatio, contentMode: .fit)
                .overlay { media() }
                .clipped()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            if let badge, !badge.isEmpty {
                PlatformMediaCaptionBadge(title: badge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(PlatformMetrics.captionBadgeInset)
        }
        .aspectRatio(PlatformMetrics.profileLibraryCardAspectRatio, contentMode: .fit)
        .clipShape(PlatformMetrics.posterShape)
        .contentShape(PlatformMetrics.posterShape)
        .colorScheme(.dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)，\(subtitle)")
    }
}
