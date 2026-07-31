//
//  ProfileLibraryComponents.swift
//  坐标系
//
//  「我的」一级页共用件：圈子海报卡、发布分享菜单、空态、文案。
//

import SwiftUI

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

/// 圈子轨竖海报。
struct ProfileLibraryShelfCard<Media: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let subtitle: String
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

// MARK: - Hosted star

/// 「我发起的」星标：叠在活动长条右上角，区分参加与发起。
struct ProfileHostedStarMark: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.yellow)
            .symbolRenderingMode(.hierarchical)
            .padding(PlatformMetrics.captionBadgeInset)
            .background(.ultraThinMaterial, in: Circle())
            .accessibilityLabel("我发起的")
            .accessibilityAddTraits(.isStaticText)
    }
}

/// 「我的活动」顶栏：文案切换「只看发起」/「全部」，与票面星标含义分离。
struct ProfileHostedStarFilterButton: View {
    @Binding var showHostedOnly: Bool

    var body: some View {
        Button(showHostedOnly ? "全部" : "只看发起") {
            showHostedOnly.toggle()
        }
        .accessibilityLabel(showHostedOnly ? "显示全部活动" : "只看我发起的")
        .accessibilityHint("筛选你发起的活动")
        .accessibilityAddTraits(showHostedOnly ? .isSelected : [])
    }
}
