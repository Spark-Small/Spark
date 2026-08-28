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

// MARK: - Credential card row

extension View {
    /// 发布凭证夹横卡：统一 List 行 inset（与票面轨一致）。
    func platformProfileCredentialCardRow() -> some View {
        listRowInsets(
            EdgeInsets(
                top: PlatformMetrics.sectionHeaderSpacing,
                leading: PlatformMetrics.contentInset,
                bottom: PlatformMetrics.sectionHeaderSpacing,
                trailing: PlatformMetrics.contentInset
            )
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Gated row
struct ProfileFormGatedRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                    .platformContentSymbolStyle()
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

/// 帖子 / 关注 / 粉丝：Form 行内默认 `HStack` 等宽三列。
struct ProfileSocialStatsRow: View {
    let postCount: Int
    let followingCount: Int
    let fansCount: Int

    var body: some View {
        HStack {
            cell(value: "\(postCount)", label: "帖子")
            cell(value: "\(followingCount)", label: "关注")
            cell(value: "\(fansCount)", label: "粉丝")
        }
    }

    private func cell(value: String, label: String) -> some View {
        VStack(spacing: PlatformMetrics.hairlineSpacing) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

@MainActor
enum ProfileSocialStats {
    static func postCount(for name: String, community: CommunityModel) -> Int {
        community.posts.filter {
            $0.author.caseInsensitiveCompare(name) == .orderedSame
                && $0.repostedFromID == nil
        }.count
    }

    static func followingCount(for name: String, app: AppModel) -> Int {
        if name.caseInsensitiveCompare(app.user.name) == .orderedSame {
            return app.followedUserNames.count
        }
        return SampleData.author(named: name).hostedCount
    }

    static func fansCount(for name: String, app: AppModel) -> Int {
        var fans = SampleData.author(named: name).joinedCount
        if name.caseInsensitiveCompare(app.user.name) != .orderedSame, app.isFollowing(name) {
            fans += 1
        }
        return fans
    }
}
