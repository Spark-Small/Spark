// Module: SparkLikes — Opening line suggestions for new matches.

import Foundation

public enum LikesIcebreakerSuggestions {
    public static func suggestions(for card: DiscoverCard) -> [String] {
        var lines: [String] = []
        if let activity = card.sharedActivityTitle, !activity.isEmpty {
            let format = String(
                localized: "likes.icebreaker.activity.format",
                defaultValue: "我也对「%@」感兴趣，一起？",
                comment: "Icebreaker activity; %@ is title"
            )
            lines.append(String(format: format, locale: .current, activity))
        }
        if let tag = card.interestTags.first {
            let format = String(
                localized: "likes.icebreaker.tag.format",
                defaultValue: "看到你也喜欢 %@，想聊聊",
                comment: "Icebreaker tag; %@ is tag"
            )
            lines.append(String(format: format, locale: .current, tag))
        }
        if !card.bio.isEmpty {
            let format = String(
                localized: "likes.icebreaker.bio.format",
                defaultValue: "你好 %@，你的简介很有意思",
                comment: "Icebreaker bio; %@ is name"
            )
            lines.append(String(format: format, locale: .current, card.displayName))
        }
        lines.append(
            String(
                localized: "likes.icebreaker.hello",
                defaultValue: "你好，很高兴配对成功",
                comment: "Generic icebreaker"
            )
        )
        return Array(lines.prefix(3))
    }
}
