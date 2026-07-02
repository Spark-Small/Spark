// Module: SparkBuddy — Display strings for listings.

import Foundation

enum BuddyFormatting {
    static func priceLine(amount: Decimal, currencyCode: String, billingKind: BuddyBillingKind) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        let amountText = formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return amountText + billingKind.localizedUnitSuffix
    }

    static func ratingLine(rating: Double?, reviewCount: Int) -> String? {
        guard let rating, reviewCount > 0 else { return nil }
        let format = String(
            localized: "buddy.rating.format",
            defaultValue: "%.1f · %lld 条评价",
            comment: "Rating line; first is score, second is review count"
        )
        return String(format: format, locale: .current, rating, reviewCount)
    }

    static func ratingScoreText(_ rating: Double) -> String {
        String(format: "%.1f", locale: .current, rating)
    }

    static func reviewCountText(_ reviewCount: Int) -> String {
        String(
            format: String(
                localized: "buddy.review.count.format",
                defaultValue: "%lld 条评价",
                comment: "Review count label"
            ),
            locale: .current,
            reviewCount
        )
    }

    static func compactRatingText(rating: Double, reviewCount: Int) -> String {
        String(
            format: String(
                localized: "buddy.rating.compact.format",
                defaultValue: "%@ (%lld)",
                comment: "Compact rating; score and review count"
            ),
            locale: .current,
            ratingScoreText(rating),
            reviewCount
        )
    }

    /// Browse list row: score + completed order count (no star glyphs).
    static func listRatingLine(rating: Double?, completedOrderCount: Int, reviewCount: Int) -> String? {
        guard let rating else { return nil }
        if completedOrderCount > 0 {
            let format = String(
                localized: "buddy.rating.list.orders.format",
                defaultValue: "%@ · %lld单",
                comment: "Browse list rating with completed orders"
            )
            return String(format: format, locale: .current, ratingScoreText(rating), completedOrderCount)
        }
        guard reviewCount > 0 else { return ratingScoreText(rating) }
        let format = String(
            localized: "buddy.rating.list.reviews.format",
            defaultValue: "%@ · %lld条评价",
            comment: "Browse list rating with review count fallback"
        )
        return String(format: format, locale: .current, ratingScoreText(rating), reviewCount)
    }

    static func starRatingAccessibilityLabel(rating: Double) -> String {
        String(
            format: String(
                localized: "buddy.rating.stars.a11y.format",
                defaultValue: "评分 %@ 分，满分 5 分",
                comment: "Star rating accessibility"
            ),
            locale: .current,
            ratingScoreText(rating)
        )
    }

    static func reviewDateText(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    static func packagePriceLine(amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    static func matchLine(_ insight: BuddyMatchInsight) -> String {
        let format = String(
            localized: "buddy.match.format",
            defaultValue: "匹配度 %lld%%",
            comment: "Match percent line"
        )
        return String(format: format, locale: .current, insight.matchPercent)
    }

    static func serviceLine(supportsPaidCompanion: Bool, supportsOfflineMeetup: Bool) -> String {
        switch (supportsPaidCompanion, supportsOfflineMeetup) {
        case (true, true):
            String(
                localized: "buddy.service.both",
                defaultValue: "付费陪玩 · 线下聚会",
                comment: "Both service types"
            )
        case (true, false):
            String(
                localized: "buddy.service.paidCompanion",
                defaultValue: "付费陪玩",
                comment: "Paid companion only"
            )
        case (false, true):
            String(
                localized: "buddy.service.offlineMeetup",
                defaultValue: "线下聚会搭子",
                comment: "Offline meetup only"
            )
        case (false, false):
            String(
                localized: "buddy.service.general",
                defaultValue: "搭子服务",
                comment: "Generic buddy service"
            )
        }
    }
}
