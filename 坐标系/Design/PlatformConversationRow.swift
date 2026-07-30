//
//  PlatformConversationRow.swift
//  坐标系
//
//  消息列表行：主/副文用 SwiftUI 系统字号；间距取自 subtitleCell。
//  不用行内 UIListContentView（与 SwiftUI 头像混排会产生垂直偏差）。
//  例外：头像、未读红点、在线绿点。
//

import SwiftUI
import UIKit

// MARK: - List typography（行高 = UIFont textStyle；间距 = subtitleCell 探针）

enum PlatformListTypography {
    static var body: Font { Font(UIFont.preferredFont(forTextStyle: .body)) }
    static var primary: Font { Font(primaryUIFont) }
    static var secondary: Font { Font(UIFont.preferredFont(forTextStyle: .subheadline)) }
    static var footnote: Font { Font(UIFont.preferredFont(forTextStyle: .footnote)) }
    static var trailing: Font { secondary }

    static var primaryUIFont: UIFont {
        let metrics = UIFontMetrics(forTextStyle: .body)
        let base = UIFont.preferredFont(forTextStyle: .body)
        let semibold = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
        return metrics.scaledFont(for: semibold)
    }
}

/// 列表行内操作 SF Symbol：`UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)`。
enum PlatformListActionSymbol {
    static var font: Font { PlatformListTypography.body }
    static var imageScale: Image.Scale { .medium }
    static var countFont: Font { PlatformListTypography.footnote }
    static var trailingTextSpacing: CGFloat { PlatformMetrics.hairlineSpacing }
}

/// subtitleCell 主 / 副 / 辅助文列（Feed、详情、评论等复用）。
struct PlatformListTextColumn: View {
    let primary: String
    var secondary: String? = nil
    var footnote: String? = nil
    var primaryLineLimit: Int? = nil
    var secondaryLineLimit: Int? = nil
    var footnoteLineLimit: Int? = nil
    var allowsSecondarySelection: Bool = false

    private var trimmedSecondary: String? {
        guard let secondary else { return nil }
        let trimmed = secondary.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var trimmedFootnote: String? {
        guard let footnote else { return nil }
        let trimmed = footnote.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            Text(primary)
                .font(PlatformListTypography.primary)
                .foregroundStyle(.primary)
                .lineLimit(primaryLineLimit)
                .multilineTextAlignment(.leading)

            if let trimmedSecondary {
                Group {
                    if allowsSecondarySelection {
                        Text(trimmedSecondary)
                            .textSelection(.enabled)
                    } else {
                        Text(trimmedSecondary)
                    }
                }
                .font(PlatformListTypography.secondary)
                .foregroundStyle(.secondary)
                .lineLimit(secondaryLineLimit)
                .multilineTextAlignment(.leading)
            }

            if let trimmedFootnote {
                Text(trimmedFootnote)
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(footnoteLineLimit)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

/// 列表行作者头：头像 + 主文 + 右侧时间（与 `PlatformConversationRow` 同构）。
struct PlatformListAuthorLine: View {
    let name: String
    let time: Date
    var isPinned: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformSystemAvatar(side: PlatformConversationListRow.imageSide)

            Text(name)
                .font(PlatformListTypography.primary)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                if isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(MessagesCopy.pin)
                }
                Text(Formatters.conversationListTime(from: time))
                    .font(PlatformListTypography.trailing)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Conversation row

/// 系统 subtitle 会话行。
struct PlatformConversationRow: View {
    var title: String
    /// `nil` / 空：仅标题（通讯录）
    var subtitle: String? = nil
    var time: Date? = nil
    var isUnread: Bool = false
    var isPinned: Bool = false
    var isMuted: Bool = false
    var showsPresence: Bool = false

    private var subtitleText: String? {
        guard let subtitle else { return nil }
        let trimmed = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var showsTrailing: Bool {
        time != nil
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            avatar

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(title)
                    .font(isUnread ? PlatformListTypography.primary : PlatformListTypography.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let subtitleText {
                    Text(subtitleText)
                        .font(PlatformListTypography.secondary)
                        .foregroundStyle(isUnread ? .primary : .secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsTrailing {
                trailingContent
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var trailingContent: some View {
        if let time {
            VStack(alignment: .trailing, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.tertiary)
                            .accessibilityLabel(MessagesCopy.pin)
                    }
                    Text(Formatters.conversationListTime(from: time))
                        .foregroundStyle(isUnread ? Color.accentColor : Color.secondary)
                        .monospacedDigit()
                }
                .font(PlatformListTypography.trailing)
                if isMuted {
                    Image(systemName: "bell.slash.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(MessagesCopy.mute)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var avatar: some View {
        ZStack(alignment: .topTrailing) {
            PlatformSystemAvatar(side: PlatformConversationListRow.imageSide)
            if isUnread {
                PlatformUnreadDot()
                    .offset(
                        x: PlatformMetrics.avatarBadgeOffset,
                        y: -PlatformMetrics.avatarBadgeOffset
                    )
            } else if showsPresence {
                PlatformPresenceDot()
                    .offset(
                        x: PlatformMetrics.avatarBadgeOffset,
                        y: -PlatformMetrics.avatarBadgeOffset
                    )
                    .accessibilityLabel(MessagesCopy.activeNow)
            }
        }
        .accessibilityHidden(true)
    }
}
