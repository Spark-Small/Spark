//
//  ProfileLibraryComponents.swift
//  坐标系
//
//  「我的」一级页内容预览组件：发布媒体行、竖海报、空态。
//

import SwiftUI

struct ProfilePublishedLibraryLabel<Media: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let subtitle: String
    @ViewBuilder var media: () -> Media

    var body: some View {
        Group {
            if DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize) {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    thumbnail
                        .frame(maxWidth: .infinity)
                    copy
                }
            } else {
                HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                    thumbnail
                        .platformProfileMediaLibraryThumbnailFrame()
                    copy
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var thumbnail: some View {
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
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(DiscoverAccessibility.bodyLineLimit(for: dynamicTypeSize, regular: 2))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 发布行尾部系统更多菜单（分享）。
struct ProfilePublishedShareMenu: View {
    let shareText: String
    let accessibilityTitle: String

    var body: some View {
        Menu {
            ShareLink(item: shareText) {
                Label("分享", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
        }
        .buttonStyle(.plain)
        .controlSize(.large)
        .accessibilityLabel("更多，\(accessibilityTitle)")
    }
}

struct ProfileLibraryShelfCard<Media: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let subtitle: String
    var badge: String? = nil
    @ViewBuilder var media: () -> Media

    var body: some View {
        Group {
            if DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize) {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    cover
                    copy(onMedia: false)
                }
            } else {
                overlayBody
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)，\(subtitle)")
    }

    private var overlayBody: some View {
        ZStack {
            cover

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            if let badge, !badge.isEmpty {
                PlatformMediaCaptionBadge(title: badge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            copy(onMedia: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(PlatformMetrics.captionBadgeInset)
        }
        .aspectRatio(PlatformMetrics.profileLibraryCardAspectRatio, contentMode: .fit)
        .clipShape(PlatformMetrics.posterShape)
        .contentShape(PlatformMetrics.posterShape)
        .colorScheme(.dark)
    }

    private var cover: some View {
        Color.clear
            .aspectRatio(PlatformMetrics.profileLibraryCardAspectRatio, contentMode: .fit)
            .overlay { media() }
            .clipped()
            .clipShape(PlatformMetrics.posterShape)
            .overlay(alignment: .topLeading) {
                if DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize),
                   let badge,
                   !badge.isEmpty {
                    PlatformMediaCaptionBadge(title: badge)
                }
            }
    }

    private func copy(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(onMedia ? .white : .primary)
                .multilineTextAlignment(.leading)
                .lineLimit(DiscoverAccessibility.bodyLineLimit(for: dynamicTypeSize, regular: 2))

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(onMedia ? .white.opacity(0.82) : .secondary)
                .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
        }
    }
}

/// 圈子轨封面：浅色底 + 多色 SF Symbol。
struct ProfileCircleShelfCover: View {
    let systemImage: String

    var body: some View {
        Color.accentColor.opacity(0.14)
            .overlay {
                Image(systemName: systemImage)
                    .font(.title2)
                    .platformSymbolStyle(.multicolor)
            }
    }
}

/// 「我的陪玩」预约预览：与圈子共用个人内容库竖海报规格。
struct ProfileBookingShelfCard: View {
    let record: BuddyBookingRecord
    let photo: CommunityPhotoRef?

    var body: some View {
        ProfileLibraryShelfCard(
            title: record.companionNickname,
            subtitle: "\(scheduleLine) · \(record.priceText)",
            badge: record.statusLabel
        ) {
            CommunityRemotePhoto(ref: photo)
        }
    }

    private var scheduleLine: String {
        "\(Formatters.monthDay.string(from: record.scheduledAt)) \(Formatters.shortTime.string(from: record.scheduledAt))"
    }
}

enum ProfileLibraryCopy {
    static func postMetaLine(for post: CommunityPost) -> String {
        [
            Formatters.conversationListTime(from: post.postedAt),
            "赞 \(post.likeCount)",
            "评 \(post.commentCount)"
        ].joined(separator: " · ")
    }

    static func activityShareText(for activity: Activity) -> String {
        "【坐标系·活动】\(activity.title)\n\(Formatters.activityEventTime(from: activity.date))\n\(activity.location)"
    }
}

/// 「我的」货架空态：全宽 + 内容边距。
struct ProfileShelfEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PlatformMetrics.contentInset)
    }
}
