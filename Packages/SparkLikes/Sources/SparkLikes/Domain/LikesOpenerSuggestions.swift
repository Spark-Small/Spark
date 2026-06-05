// Module: SparkLikes — Compliment-style opener bubbles for like gestures.

import Foundation

public enum LikesOpenerSuggestions {
    public static func suggestions(for card: DiscoverCard) -> [String] {
        var lines: [String] = [
            String(
                localized: "likes.opener.smile",
                defaultValue: "你的笑容很治愈",
                comment: "Opener smile"
            ),
            String(
                localized: "likes.opener.hello",
                defaultValue: "你好，很想认识你",
                comment: "Opener hello"
            )
        ]
        if let activity = card.sharedActivityTitle, !activity.isEmpty {
            let format = String(
                localized: "likes.opener.activity.format",
                defaultValue: "想和你去「%@」",
                comment: "Opener activity; %@ is title"
            )
            lines.append(String(format: format, locale: .current, activity))
        }
        if let tag = card.interestTags.first {
            let format = String(
                localized: "likes.opener.tag.format",
                defaultValue: "你也玩 %@ ？",
                comment: "Opener tag; %@ is tag"
            )
            lines.append(String(format: format, locale: .current, tag))
        }
        if let question = card.sparkQuestions.first {
            let format = String(
                localized: "likes.opener.question.format",
                defaultValue: "关于「%@」的回答很棒",
                comment: "Opener question; %@ is prompt"
            )
            lines.append(String(format: format, locale: .current, question.question))
        }
        lines.append(
            String(
                localized: "likes.opener.niceProfile",
                defaultValue: "你的资料很有意思",
                comment: "Opener profile"
            )
        )
        return Array(lines.prefix(6))
    }
}
