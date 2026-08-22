//
//  BuddyPaidMarketViews.swift
//  坐标系
//
//  陪玩发现页：精选横滑 · 排行榜（穿插系统级快捷长条）。
//  类目来自现有服务类型 / 擅长关键词，不硬编码游戏品类树。
//

import SwiftUI

// MARK: - Quick entry

enum BuddyPaidQuickEntry: String, Identifiable {
    case voiceParty
    case quickMatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickMatch: BuddyPaidBrowseCopy.quickMatchTitle
        case .voiceParty: BuddyPaidBrowseCopy.voicePartyTitle
        }
    }

    var subtitle: String {
        switch self {
        case .quickMatch: BuddyPaidBrowseCopy.quickMatchSubtitle
        case .voiceParty: BuddyPaidBrowseCopy.voicePartySubtitle
        }
    }

    var systemImage: String {
        switch self {
        case .quickMatch: "bolt.fill"
        case .voiceParty: "speaker.wave.2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .quickMatch: .indigo
        case .voiceParty: .purple
        }
    }
}

/// 系统级列表长条：与排行榜行同高，全宽一条一行动作
struct BuddyPaidQuickEntryBar: View {
    let entry: BuddyPaidQuickEntry
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                Image(systemName: entry.systemImage)
                    .font(PlatformListTypography.body)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(entry.tint)
                    .frame(width: 36, height: 36)
                    .background(
                        entry.tint.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous)
                    )
                    .accessibilityHidden(true)

                PlatformListTextColumn(
                    primary: entry.title,
                    secondary: entry.subtitle,
                    primaryLineLimit: 1,
                    secondaryLineLimit: 1
                )

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, PlatformMetrics.cardInfoSpacing)
            .padding(.vertical, PlatformConversationListRow.verticalInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
            .contentShape(PlatformMetrics.cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.title)，\(entry.subtitle)")
        .accessibilityHint("打开\(entry.title)")
    }
}

enum BuddyPaidLeaderboardFeedItem: Identifiable {
    case companion(DiscoverBuddyItem, rank: Int)
    case promo(BuddyPaidQuickEntry)

    var id: String {
        switch self {
        case .companion(let item, let rank): "companion-\(item.id)-\(rank)"
        case .promo(let entry): "promo-\(entry.rawValue)"
        }
    }
}

enum BuddyPaidLeaderboardFeedPlanner {
    /// 在推荐榜行之间穿插快捷长条：前段语音、中段匹配，随列表长度自适应
    static func buildFeed(from items: [DiscoverBuddyItem], maxRows: Int = 10) -> [BuddyPaidLeaderboardFeedItem] {
        let rows = Array(items.prefix(maxRows))
        guard !rows.isEmpty else { return [] }

        let placements = promoPlacements(rowCount: rows.count)
        var feed: [BuddyPaidLeaderboardFeedItem] = []

        for (index, item) in rows.enumerated() {
            let rank = index + 1
            feed.append(.companion(item, rank: rank))
            for placement in placements where placement.insertAfterRank == rank {
                feed.append(.promo(placement.entry))
            }
        }
        return feed
    }

    private static func promoPlacements(rowCount: Int) -> [(insertAfterRank: Int, entry: BuddyPaidQuickEntry)] {
        var result: [(insertAfterRank: Int, entry: BuddyPaidQuickEntry)] = []
        let voiceAfter = min(2, rowCount)
        result.append((insertAfterRank: voiceAfter, entry: .voiceParty))

        let matchAfter = min(max(4, rowCount / 2 + 1), rowCount)
        if matchAfter != voiceAfter {
            result.append((insertAfterRank: matchAfter, entry: .quickMatch))
        } else if rowCount >= 3 {
            result.append((insertAfterRank: min(voiceAfter + 2, rowCount), entry: .quickMatch))
        }
        return result.sorted { $0.insertAfterRank < $1.insertAfterRank }
    }
}

enum BuddyPaidHotBadge: String, CaseIterable, Hashable {
    case recommended = "推荐"
    case booming = "火爆"
    case popular = "热门"
    case rising = "新晋"
    case topRated = "高评"
    case quickReply = "秒回"
    case reputation = "口碑好"
    case trending = "飙升"
    case reliable = "靠谱"
    case gem = "宝藏"
    case repeatGuest = "回头客"
    case valuePick = "超值"

    var tint: Color {
        switch self {
        case .recommended: Color.accentColor
        case .booming: .pink
        case .popular: .orange
        case .rising: .mint
        case .topRated: .yellow
        case .quickReply: .cyan
        case .reputation: .purple
        case .trending: .indigo
        case .reliable: PlatformStatus.success
        case .gem: .teal
        case .repeatGuest: .brown
        case .valuePick: .blue
        }
    }

    /// Top 卡角标：按名次、成单、评分、响应稳定推导，避免人人「热门」
    @MainActor
    static func forCompanion(_ companion: PaidCompanion, rank: Int) -> BuddyPaidHotBadge {
        let rating = BuddyPaidMarketCatalog.displayRating(for: companion)
        let reviews = BuddyPaidMarketCatalog.reviewCount(for: companion)
        let seed = abs(companion.id.hashValue &+ rank &* 13)

        if rank == 1 { return .recommended }
        if companion.orderCount >= 120 { return .booming }
        if rating >= 4.9, reviews >= 24 { return .topRated }
        if isQuickResponder(companion) { return .quickReply }
        if companion.orderCount >= 80, reviews >= 30 { return .repeatGuest }
        if rank <= 2, companion.orderCount >= 60 { return .popular }
        if reviews >= 36 { return .reputation }
        if companion.orderCount < 45, rank <= 4 { return .rising }
        if companion.hourlyPrice <= 99, companion.isAvailable { return .valuePick }
        if seed % 5 == 0 { return .trending }
        if companion.isVerified, companion.isAvailable { return .reliable }
        if seed % 3 == 0 { return .gem }

        let pool: [BuddyPaidHotBadge] = [.popular, .rising, .reputation, .trending, .gem, .reliable]
        return pool[seed % pool.count]
    }

    private static func isQuickResponder(_ companion: PaidCompanion) -> Bool {
        let text = companion.responseTime
        guard text.localizedCaseInsensitiveContains("分钟") else { return false }
        let digits = text.filter(\.isNumber)
        guard let minutes = Int(digits.prefix(2)) else {
            return text.contains("10") || text.contains("15") || text.contains("20")
        }
        return minutes <= 20
    }
}

enum BuddyPaidBoardPeriod: String, CaseIterable, Identifiable {
    case day = "日榜"
    case week = "周榜"
    case month = "月榜"

    var id: String { rawValue }
}

enum BuddyPaidMarketCatalog {
    static func shortSpecialty(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let head = trimmed.split(separator: "/").first {
            let piece = String(head).trimmingCharacters(in: .whitespacesAndNewlines)
            if piece.count <= 8 { return piece }
            return String(piece.prefix(8))
        }
        if trimmed.count <= 8 { return trimmed }
        return String(trimmed.prefix(8))
    }

    static func ranked(
        _ items: [DiscoverBuddyItem],
        period: BuddyPaidBoardPeriod
    ) -> [DiscoverBuddyItem] {
        let paid: [(DiscoverBuddyItem, PaidCompanion)] = items.compactMap {
            guard case .paid(let companion) = $0 else { return nil }
            return ($0, companion)
        }
        let sorted = paid.sorted { lhs, rhs in
            let left = boardScore(lhs.1, period: period)
            let right = boardScore(rhs.1, period: period)
            if left != right { return left > right }
            return lhs.1.hourlyPrice < rhs.1.hourlyPrice
        }
        return sorted.map(\.0)
    }

    static func boardScore(_ companion: PaidCompanion, period: BuddyPaidBoardPeriod) -> Int {
        let base = companion.orderCount
        switch period {
        case .day:
            return max(1, base / 12) + (companion.isAvailable ? 8 : 0)
        case .week:
            return max(1, base / 4) + (companion.isVerified ? 5 : 0)
        case .month:
            return base
        }
    }

    /// 榜行展示分：优先读评价库，无数据时用成单量推导演示分
    @MainActor
    static func displayRating(for companion: PaidCompanion) -> Double {
        PlatformReviewCatalog.displayRating(for: companion)
    }

    @MainActor
    static func reviewCount(for companion: PaidCompanion) -> Int {
        PlatformReviewCatalog.reviewCount(for: companion)
    }

    static func leaderboardTags(for companion: PaidCompanion, limit: Int = 2) -> [String] {
        Array(companion.profile.tags.prefix(limit))
    }

    /// 榜行平台角标（Top 10 展示；与性格亮点区分）
    @MainActor
    static func leaderboardHotBadge(for companion: PaidCompanion, rank: Int) -> BuddyPaidHotBadge? {
        guard rank <= 10 else { return nil }
        return BuddyPaidHotBadge.forCompanion(companion, rank: rank)
    }

    /// 榜行个人亮点：他人评价 / 性格标签（非平台指标）
    static func leaderboardHighlights(for companion: PaidCompanion, limit: Int = 2) -> [String] {
        var boosted: [String] = []
        let specialty = companion.specialty

        switch companion.serviceType {
        case .voice:
            boosted += ["声音好听", "善于倾听", "聊天不尬"]
        case .sport:
            boosted += ["节奏稳定", "新手友好", "鼓励型"]
        case .offline:
            boosted += ["懂氛围", "不冷场", "会找店"]
        case .photo:
            boosted += ["会找角度", "出片快", "审美在线"]
        }

        switch companion.profile.gender {
        case .female:
            boosted += ["甜美可人", "细心体贴", "温柔耐心"]
        case .male:
            boosted += ["阳光开朗", "靠谱领队", "风趣幽默"]
        }

        if specialty.localizedCaseInsensitiveContains("陪吃")
            || specialty.localizedCaseInsensitiveContains("火锅")
            || specialty.localizedCaseInsensitiveContains("探店") {
            boosted.append("懂氛围")
        }
        if specialty.localizedCaseInsensitiveContains("陪练")
            || specialty.localizedCaseInsensitiveContains("羽毛球") {
            boosted.append("专业认真")
        }

        let general = [
            "风趣幽默", "温柔耐心", "准时靠谱", "氛围轻松",
            "沟通顺畅", "专业认真", "节奏稳定", "不冷场",
            "很会聊", "有耐心", "懂路线", "超预期"
        ]

        var candidates: [String] = []
        var seen = Set<String>()
        for item in boosted + general where seen.insert(item).inserted {
            candidates.append(item)
        }

        let seed = abs(companion.id.hashValue)
        var picked: [String] = []
        var index = 0
        while picked.count < limit, index < candidates.count * 2 {
            let trait = candidates[(seed + index * 5) % candidates.count]
            if !picked.contains(trait) {
                picked.append(trait)
            }
            index += 1
        }
        return picked
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

// MARK: - Featured companion card

/// 陪玩页精选大卡：全宽人像 + 底栏信息与 CTA（同列不重叠）
struct BuddyFeaturedCompanionCard: View {
    let companion: PaidCompanion
    var slot: String = "hero"
    var usesRailLayout = false
    var zoomNamespace: Namespace.ID
    var onBook: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var item: DiscoverBuddyItem { .paid(companion) }

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    coverLink
                    footerChrome(onMedia: false)
                        .padding(.horizontal, PlatformMetrics.contentInset)
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
                        footerInfo(onMedia: true)
                        footerAction(onMedia: true)
                            .layoutPriority(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .padding(PlatformMetrics.contentInset)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        .clipShape(PlatformMetrics.cardShape)
        .contentShape(PlatformMetrics.cardShape)
        .padding(.horizontal, usesRailLayout ? 0 : PlatformMetrics.contentInset)
    }

    private var coverLink: some View {
        BuddyZoomNavigationLink(item: item, slot: slot, namespace: zoomNamespace) {
            Color.clear
                .aspectRatio(PlatformMetrics.editorialCardAspectRatio, contentMode: .fit)
                .overlay {
                    CommunityRemotePhoto(ref: companion.profile.coverPhoto)
                }
                .overlay {
                    if !prefersStacked {
                        LinearGradient(
                            colors: [.black.opacity(0.72), .black.opacity(0.18), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    }
                }
                .clipped()
        }
        .accessibilityLabel("\(companion.profile.nickname)，\(companion.priceText)")
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private func footerChrome(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardFooterSpacing) {
            footerInfo(onMedia: onMedia)
            footerAction(onMedia: onMedia)
        }
    }

    private func footerInfo(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            HStack(spacing: PlatformMetrics.minContentGap) {
                Text(companion.profile.nickname)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if companion.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityLabel("平台认证")
                }
            }
            HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                Label(companion.priceText, systemImage: "tag")
                Label("\(companion.orderCount) 单", systemImage: "checkmark.rectangle")
                if companion.isAvailable {
                    Label("可约", systemImage: "calendar")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func footerAction(onMedia: Bool) -> some View {
        Button(companion.isAvailable ? "下单" : "暂不可约", action: onBook)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: onMedia ? nil : .infinity, alignment: .leading)
        .activityPrimaryCTA()
        .disabled(!companion.isAvailable)
        .colorScheme(onMedia ? .dark : .light)
    }
}

/// 精选大卡横滑轨：左滑切换，邻卡露出提示可继续浏览
struct BuddyFeaturedCompanionRail: View {
    let companions: [PaidCompanion]
    var zoomNamespace: Namespace.ID
    var onBook: (PaidCompanion) -> Void

    var body: some View {
        Group {
            if companions.count <= 1, let companion = companions.first {
                BuddyFeaturedCompanionCard(
                    companion: companion,
                    slot: "hero-0",
                    zoomNamespace: zoomNamespace,
                    onBook: { onBook(companion) }
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(Array(companions.enumerated()), id: \.element.id) { index, companion in
                        BuddyFeaturedCompanionCard(
                            companion: companion,
                            slot: "hero-\(index)",
                            usesRailLayout: true,
                            zoomNamespace: zoomNamespace,
                            onBook: { onBook(companion) }
                        )
                        .platformEditorialRailFrame()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("精选陪玩")
    }
}

// MARK: - Leaderboard

struct BuddyPaidLeaderboard: View {
    let items: [DiscoverBuddyItem]
    @Binding var period: BuddyPaidBoardPeriod
    var zoomNamespace: Namespace.ID
    var onBook: (DiscoverBuddyItem) -> Void
    var onQuickEntry: (BuddyPaidQuickEntry) -> Void

    private var topThree: [DiscoverBuddyItem] { Array(items.prefix(3)) }
    private var feedItems: [BuddyPaidLeaderboardFeedItem] {
        BuddyPaidLeaderboardFeedPlanner.buildFeed(from: items)
    }

    var body: some View {
        DiscoverBrowseSection(
            title: "推荐陪玩",
            subtitle: "成单多 · 响应快 · 近期可约"
        ) {
            VStack(spacing: PlatformMetrics.discoverCardSpacing) {
                if !topThree.isEmpty {
                    // 轨自带 contentInset，勿再外包一层水平边距
                    DiscoverHorizontalRail {
                        ForEach(Array(topThree.enumerated()), id: \.element.id) { index, item in
                            if case .paid(let companion) = item {
                                BuddyPaidTopCard(
                                    rank: index + 1,
                                    companion: companion,
                                    badge: .forCompanion(companion, rank: index),
                                    zoomNamespace: zoomNamespace,
                                    onBook: { onBook(item) }
                                )
                                .platformPosterRailFrame()
                            }
                        }
                    }
                }

                VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    HStack(spacing: PlatformMetrics.minContentGap) {
                        Text("排行榜")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer(minLength: PlatformMetrics.minContentGap)
                        Menu {
                            ForEach(BuddyPaidBoardPeriod.allCases) { option in
                                Button {
                                    period = option
                                } label: {
                                    Label(option.rawValue, systemImage: period == option ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                                Text(period.rawValue)
                                    .font(.caption.weight(.medium))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(feedItems) { feedItem in
                        switch feedItem {
                        case .companion(let item, let rank):
                            if case .paid(let companion) = item {
                                BuddyPaidLeaderboardRow(
                                    rank: rank,
                                    companion: companion,
                                    zoomNamespace: zoomNamespace,
                                    onBook: { onBook(item) }
                                )
                            }
                        case .promo(let entry):
                            BuddyPaidQuickEntryBar(entry: entry) {
                                onQuickEntry(entry)
                            }
                        }
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
            }
        }
    }
}

/// Top 3 奖牌竖卡：封面叠字 + 卡内下单，信息不与按钮重叠
struct BuddyPaidTopCard: View {
    let rank: Int
    let companion: PaidCompanion
    let badge: BuddyPaidHotBadge
    var zoomNamespace: Namespace.ID
    var onBook: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var item: DiscoverBuddyItem { .paid(companion) }

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    coverLink
                    footerChrome(onMedia: false)
                        .padding(.horizontal, PlatformMetrics.captionBadgeInset)
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
                        topCardMeta(onMedia: true)
                        topCardAction(onMedia: true)
                            .layoutPriority(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .padding(PlatformMetrics.captionBadgeInset)
                }
            }
        }
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        .clipShape(PlatformMetrics.cardShape)
        .contentShape(PlatformMetrics.cardShape)
        .accessibilityElement(children: .contain)
    }

    private var coverLink: some View {
        BuddyZoomNavigationLink(item: item, slot: "top", namespace: zoomNamespace) {
            Color.clear
                .aspectRatio(PlatformMetrics.personGridCardAspectRatio, contentMode: .fit)
                .overlay { CommunityRemotePhoto(ref: companion.profile.coverPhoto) }
                .overlay(alignment: .topLeading) {
                    HStack(spacing: PlatformMetrics.hairlineSpacing) {
                        Image(systemName: rank <= 3 ? "medal.fill" : "\(rank).circle.fill")
                            .font(.caption2.weight(.bold))
                        Text(badge.rawValue)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
                    .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
                    .background(badge.tint.opacity(0.88), in: Capsule())
                    .padding(PlatformMetrics.captionBadgeInset)
                    .allowsHitTesting(false)
                }
                .overlay(alignment: .bottom) {
                    if !prefersStacked {
                        LinearGradient(
                            colors: [.black.opacity(0.75), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: PlatformMetrics.contentInset * 5)
                        .allowsHitTesting(false)
                    }
                }
                .clipped()
        }
        .accessibilityLabel("第\(rank)名，\(companion.profile.nickname)，\(companion.priceText)")
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private func footerChrome(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            topCardMeta(onMedia: onMedia)
            topCardAction(onMedia: onMedia)
        }
    }

    private func topCardMeta(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            Text(companion.profile.nickname)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(companion.orderCount) 单 · \(companion.priceText)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func topCardAction(onMedia: Bool) -> some View {
        Button(companion.isAvailable ? "下单" : "暂不可约", action: onBook)
            .font(.caption.weight(.semibold))
            .activityPrimaryCTA(controlSize: .mini)
            .disabled(!companion.isAvailable)
            .colorScheme(onMedia ? .dark : .light)
            .layoutPriority(1)
    }
}

/// 排行榜行：系统字阶 + subtitleCell 图文/主副间距；右侧小 CTA
struct BuddyPaidLeaderboardRow: View {
    let rank: Int
    let companion: PaidCompanion
    var zoomNamespace: Namespace.ID
    var onBook: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var item: DiscoverBuddyItem { .paid(companion) }

    /// 榜行头像用「好友动态封面」档，约列表头像 × 1.6
    private var avatarSide: CGFloat { dynamicTypeSize.friendPostCoverSide }

    private var displayRating: Double {
        BuddyPaidMarketCatalog.displayRating(for: companion)
    }

    private var reviewCount: Int {
        BuddyPaidMarketCatalog.reviewCount(for: companion)
    }

    private var displayTags: [String] {
        BuddyPaidMarketCatalog.leaderboardTags(for: companion)
    }

    private var displayHighlights: [String] {
        BuddyPaidMarketCatalog.leaderboardHighlights(for: companion)
    }

    private var displayHotBadge: BuddyPaidHotBadge? {
        BuddyPaidMarketCatalog.leaderboardHotBadge(for: companion, rank: rank)
    }

    private var leaderboardAccessibilityLabel: String {
        var parts = [
            "第\(rank)名",
            companion.profile.nickname,
            "评分 \(String(format: "%.1f", displayRating))",
            "\(companion.orderCount) 单",
        ]
        if let displayHotBadge {
            parts.append(displayHotBadge.rawValue)
        }
        if !displayTags.isEmpty {
            parts.append("兴趣 \(displayTags.joined(separator: "、"))")
        }
        if !displayHighlights.isEmpty {
            parts.append("亮点 \(displayHighlights.joined(separator: "、"))")
        }
        parts.append(companion.priceText)
        return parts.joined(separator: "，")
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
            BuddyZoomNavigationLink(item: item, slot: "board", namespace: zoomNamespace) {
                HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                    portrait

                    VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                        HStack(spacing: PlatformMetrics.minContentGap) {
                            Text(companion.profile.nickname)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if companion.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityLabel("平台认证")
                            }
                        }

                        HStack(spacing: PlatformMetrics.minContentGap) {
                            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(String(format: "%.1f", displayRating))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                            }
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(reviewCount) 评")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(companion.orderCount) 单")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .lineLimit(1)

                        if !displayTags.isEmpty || displayHotBadge != nil || !displayHighlights.isEmpty {
                            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                                if let displayHotBadge {
                                    PlatformCaptionBadge(
                                        title: displayHotBadge.rawValue,
                                        chrome: .tint(displayHotBadge.tint)
                                    )
                                }
                                ForEach(displayTags, id: \.self) { tag in
                                    PlatformCaptionBadge(title: tag, chrome: .material)
                                }
                                ForEach(displayHighlights, id: \.self) { highlight in
                                    PlatformCaptionBadge(title: highlight, chrome: .material)
                                }
                            }
                            .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 价 ↔ 钮：与 ActivityFeaturedCard 图下「文案 + CTA」同用 cardFooterSpacing
            VStack(alignment: .trailing, spacing: PlatformMetrics.cardFooterSpacing) {
                Text(companion.priceText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PlatformStatus.warning)
                    .lineLimit(1)
                    .monospacedDigit()
                Button(companion.isAvailable ? "下单" : "暂不可约", action: onBook)
                    .font(.subheadline.weight(.semibold))
                    .activityPrimaryCTA(controlSize: .small)
                    .disabled(!companion.isAvailable)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, PlatformMetrics.cardInfoSpacing)
        .padding(.vertical, PlatformConversationListRow.verticalInset)
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            leaderboardAccessibilityLabel
        )
    }

    private var portrait: some View {
        PlatformListAvatarView(
            name: companion.profile.nickname,
            photoRef: companion.profile.coverPhoto,
            side: avatarSide
        )
        .overlay(alignment: .bottomTrailing) {
            rankBadge
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var rankBadge: some View {
        if rank <= 3 {
            Image(systemName: "medal.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(medalTint)
                .symbolRenderingMode(.hierarchical)
                .padding(PlatformMetrics.captionBadgePaddingVertical)
                .background(.thinMaterial, in: Circle())
                .accessibilityLabel("第\(rank)名")
        } else {
            Text("\(rank)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.primary)
                .padding(PlatformMetrics.captionBadgePaddingVertical)
                .background(.thinMaterial, in: Circle())
                .accessibilityLabel("第\(rank)名")
        }
    }

    private var medalTint: Color {
        switch rank {
        case 1: .yellow
        case 2: .gray
        default: .orange
        }
    }
}

// MARK: - Detail service SKUs / reviews

struct BuddyCompanionServiceSKU: Identifiable, Hashable {
    let id: String
    var title: String
    var detail: String
    var priceText: String
    var systemImage: String
    var isPrimary: Bool
    /// true：按天等议价项目，下单前双方私信对齐价格
    var isNegotiable: Bool = false
    var pricingUnit: CompanionPricingUnit? = nil
}

enum BuddyCompanionServiceMenu {
    static func skus(for companion: PaidCompanion) -> [BuddyCompanionServiceSKU] {
        var rows: [BuddyCompanionServiceSKU] = []

        switch companion.serviceType {
        case .voice:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: "语音连麦",
                    detail: "先连麦熟悉 · 可续时",
                    priceText: companion.priceText,
                    systemImage: "waveform",
                    isPrimary: true
                )
            )
            let hourPrice = max(companion.hourlyPrice * 2 - 10, companion.hourlyPrice + 15)
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "voice-hour",
                    title: "语音 1 小时",
                    detail: "深度聊天 / 开黑语音",
                    priceText: CompanionPricing.format(amount: hourPrice, unit: .hour),
                    systemImage: "mic.fill",
                    isPrimary: false
                )
            )
        case .sport:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: BuddyPaidMarketCatalog.shortSpecialty(companion.specialty),
                    detail: "1 对 1 陪练 · 按小时计费",
                    priceText: companion.priceText,
                    systemImage: companion.serviceType.systemImage,
                    isPrimary: true
                )
            )
            let pack3h = Int((Double(companion.hourlyPrice * 3) * 0.88).rounded())
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "pack-3h",
                    title: "3 小时套餐",
                    detail: "连续约满 3 小时享 88 折",
                    priceText: CompanionPricing.pack(amount: pack3h, label: "/3小时"),
                    systemImage: "clock.badge.checkmark",
                    isPrimary: false
                )
            )
            appendVoiceWarmup(to: &rows, companion: companion)
            appendDailyNegotiable(to: &rows, companion: companion)
        case .offline:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: "线下见面",
                    detail: "\(companion.specialty) · \(companion.profile.city) · 2 小时起约",
                    priceText: companion.priceText,
                    systemImage: companion.serviceType.systemImage,
                    isPrimary: true
                )
            )
            let halfDay = Int((Double(companion.hourlyPrice * 4) * 0.9).rounded())
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "half-day",
                    title: "半天陪伴",
                    detail: "约 4 小时 · 含见面等候",
                    priceText: CompanionPricing.pack(amount: halfDay, label: "/4小时"),
                    systemImage: "sun.max",
                    isPrimary: false
                )
            )
            appendVoiceWarmup(to: &rows, companion: companion)
            appendDailyNegotiable(to: &rows, companion: companion)
        case .photo:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: "跟拍 1 小时",
                    detail: "\(companion.specialty) · 含机位建议",
                    priceText: companion.priceText,
                    systemImage: companion.serviceType.systemImage,
                    isPrimary: true
                )
            )
            let sessionPrice = max(companion.hourlyPrice + 28, 128)
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "session",
                    title: "打卡套餐",
                    detail: "约 1.5 小时 · 精修 3 张",
                    priceText: CompanionPricing.format(amount: sessionPrice, unit: .session),
                    systemImage: "sparkles",
                    isPrimary: false
                )
            )
            appendVoiceWarmup(to: &rows, companion: companion)
            appendDailyNegotiable(to: &rows, companion: companion)
        }

        if companion.isAvailable {
            appendFirstOrderTrial(to: &rows, companion: companion)
        }
        return rows
    }

    private static func appendVoiceWarmup(to rows: inout [BuddyCompanionServiceSKU], companion: PaidCompanion) {
        let voicePrice = max(companion.hourlyPrice / 3, 19)
        rows.append(
            BuddyCompanionServiceSKU(
                id: "voice-warmup",
                title: "语音预热",
                detail: "见面 / 开练前先连麦对齐",
                priceText: CompanionPricing.format(amount: voicePrice, unit: .halfHour),
                systemImage: "waveform",
                isPrimary: false
            )
        )
    }

    private static func appendDailyNegotiable(to rows: inout [BuddyCompanionServiceSKU], companion: PaidCompanion) {
        rows.append(
            BuddyCompanionServiceSKU(
                id: "daily",
                title: "按天陪伴",
                detail: "全天档期 · 行程与费用双方私信商议后确认",
                priceText: CompanionPricing.negotiable,
                systemImage: "calendar.day.timeline.left",
                isPrimary: false,
                isNegotiable: true,
                pricingUnit: .day
            )
        )
    }

    private static func appendFirstOrderTrial(to rows: inout [BuddyCompanionServiceSKU], companion: PaidCompanion) {
        let trialPrice = max(Int((Double(companion.hourlyPrice) * 0.8).rounded()), 29)
        rows.append(
            BuddyCompanionServiceSKU(
                id: "trial",
                title: "首单体验",
                detail: "新客专享 · 限 1 次",
                priceText: CompanionPricing.format(amount: trialPrice, unit: companion.pricingUnit),
                systemImage: "gift",
                isPrimary: false
            )
        )
    }
}

struct BuddyCompanionServiceSKURow: View {
    let sku: BuddyCompanionServiceSKU
    var bookEnabled: Bool
    var onBook: () -> Void

    var body: some View {
        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
            Image(systemName: sku.systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: PlatformMetrics.navigationBarButtonSide, height: PlatformMetrics.navigationBarButtonSide)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(sku.title)
                    .font(.body.weight(.semibold))
                Text(sku.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: PlatformMetrics.detailMicroSpacing) {
                Text(sku.priceText)
                    .font(sku.isNegotiable ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(sku.isNegotiable ? .secondary : PlatformStatus.warning)
                Button(sku.isNegotiable ? "约聊议价" : "下单", action: onBook)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!bookEnabled)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

enum PaidCompanionDetailTab: String, CaseIterable, Identifiable {
    case profile = "资料"
    case service = "服务"
    case reviews = "评价"

    var id: String { rawValue }
}
