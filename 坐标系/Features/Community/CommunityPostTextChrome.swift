//
//  CommunityPostTextChrome.swift
//  坐标系
//
//  Feed / 详情正文、话题与作者行（发布时间在作者副文，对齐消息列表 trailing 桶；关注 CTA 仍 trailing）。
//

import SwiftUI
import CoordinateModels

/// Feed 卡片：作者行下方的正文展示（话题内联）。
struct CommunityPostFeedText: View {
    let post: CommunityPost

    var body: some View {
        Text("\(post.messageText)\(inlineTagsString)")
            .font(PlatformListTypography.body)
            .multilineTextAlignment(.leading)
            .lineLimit(1...8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inlineTagsString: AttributedString {
        CommunityInlineTags.attributedTags(post.tags)
    }
}

/// 详情页正文 + 内联话题。
struct CommunityPostBodySection: View {
    let post: CommunityPost

    var body: some View {
        Text("\(post.messageText)\(inlineTagsString)")
            .font(PlatformListTypography.body)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inlineTagsString: AttributedString {
        CommunityInlineTags.attributedTags(post.tags)
    }
}

private enum CommunityInlineTags {
    static func attributedTags(_ tags: [String]) -> AttributedString {
        var result = AttributedString()
        for tag in tags {
            var chunk = AttributedString(" #\(tag)")
            chunk.foregroundColor = .accentColor
            result.append(chunk)
        }
        return result
    }
}

/// 系统 footnote 标签行（无自定义胶囊）。
struct CommunityTagsLine: View {
    let tags: [String]

    var body: some View {
        Text(tags.joined(separator: " · "))
            .font(PlatformListTypography.footnote)
            .foregroundStyle(.secondary)
    }
}

/// Feed / 详情共用作者行：头像 + 名 / 发布时间副文；trailing 关注为系统玻璃 CTA。
struct CommunityPostAuthorHeader: View {
    let post: CommunityPost
    var onTap: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(CommunityModel.self) private var model

    private var authorName: String { post.author }

    private var isSelfAuthor: Bool {
        authorName.caseInsensitiveCompare(app.user.name) == .orderedSame
            || authorName.caseInsensitiveCompare(model.currentUserName) == .orderedSame
    }

    private var isFollowing: Bool {
        app.isFollowing(authorName)
    }

    private var postedAtText: String {
        Formatters.conversationListTime(from: post.postedAt)
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            Button(action: onTap) {
                PlatformListAvatarView(
                    name: authorName,
                    side: PlatformConversationListRow.imageSide
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(authorName)
            .accessibilityHint(CommunityAuthorCopy.authorProfileHint)

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                        Text(authorName)
                            .font(PlatformListTypography.primary)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if post.isPinned {
                            Image(systemName: "pin.fill")
                                .foregroundStyle(.tertiary)
                                .accessibilityLabel(MessagesCopy.pin)
                        }
                    }

                    Text(postedAtText)
                        .font(PlatformListTypography.trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .accessibilityLabel(CommunityEngagementCopy.postedAtAccessibility(postedAtText))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
            .accessibilityElement(children: .combine)
            .accessibilityHint(CommunityAuthorCopy.authorProfileHint)

            if !isSelfAuthor {
                Button {
                    app.toggleFollow(authorName)
                } label: {
                    Text(isFollowing ? CommunityDynamicsCopy.following : CommunityDynamicsCopy.follow)
                }
                .modifier(CommunityFollowButtonChrome(following: isFollowing, controlSize: .mini))
                .fixedSize(horizontal: true, vertical: false)
                .sensoryFeedback(.selection, trigger: isFollowing)
                .accessibilityLabel(
                    isFollowing
                        ? "\(CommunityDynamicsCopy.following)，\(authorName)"
                        : "\(CommunityDynamicsCopy.follow)，\(authorName)"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

