//
//  BuddyPersonBrowseChrome.swift
//  坐标系
//
//  搭子发现人像卡共用内容槽：封面角标 + 图下信息（+ Hero CTA）。
//  方案 A：文案图下；密度分 hero / grid。
//

import SwiftUI
import CoordinateModels

enum BuddyPersonBrowseDensity: Equatable {
    /// 精选 Hero：昵称+性别+契合+meta；封面可双角标；可带 CTA
    case hero
    /// 网格 / 辅轨 / 榜：仅昵称+meta；封面至多 1 角标；无卡内 CTA
    case grid
}

@MainActor
enum BuddyPersonBrowseChrome {
    static func affinityTags(for profile: BuddyProfile) -> [String] {
        let shared = BuddyMatchScorer.sharedHobbies(with: profile)
        guard !shared.isEmpty else { return [] }
        return Array(shared.prefix(1))
    }

    static func metaLine(for item: DiscoverBuddyItem) -> String {
        switch item {
        case .free(let buddy):
            return BuddyMatchScorer.browseMetaLine(for: buddy.profile, isOnline: buddy.isOnline)
        case .paid(let companion):
            var parts: [String] = [companion.priceText]
            parts.append(companion.isAvailable ? BuddyDetailCopy.available : BuddyDetailCopy.unavailable)
            let distance = BuddyMatchScorer.browseMetaLine(for: companion.profile, isOnline: false)
            if !distance.isEmpty {
                parts.append(distance)
            }
            return parts.joined(separator: " · ")
        }
    }

    static func intentHit(for item: DiscoverBuddyItem, query: String) -> Bool {
        BuddyMatchScorer.matchesIntent(item.profile, query: query)
    }

    static func isPaid(_ item: DiscoverBuddyItem) -> Bool {
        if case .paid = item { return true }
        return false
    }

    static func isAvailablePaid(_ item: DiscoverBuddyItem) -> Bool {
        if case .paid(let companion) = item { return companion.isAvailable }
        return false
    }
}

/// 发现人像封面：多图走系统 `TabView` 分页（与广场 `CommunityMediaPager` 同逻辑）。
struct BuddyPersonBrowseCoverMedia: View {
    let profile: BuddyProfile
    var aspectRatio: CGFloat

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                HeroPersonCover(
                    name: profile.nickname,
                    photos: profile.photoRefs,
                    allowsPaging: true
                )
            }
            .clipped()
            .clipShape(PlatformMetrics.cardShape)
            .contentShape(PlatformMetrics.cardShape)
    }
}

/// 封面角标：hero 可兴趣+可约；grid 陪玩可约/暂满优先，否则兴趣，至多 1
struct BuddyPersonBrowseCoverBadges: View {
    let item: DiscoverBuddyItem
    var density: BuddyPersonBrowseDensity = .hero

    var body: some View {
        Group {
            switch density {
            case .hero:
                ZStack {
                    affinityLeading
                    paidAvailabilityTrailing
                }
            case .grid:
                if BuddyPersonBrowseChrome.isPaid(item) {
                    paidAvailabilityTrailing
                } else {
                    affinityLeading
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var affinityLeading: some View {
        HStack(spacing: PlatformMetrics.hairlineSpacing) {
            ForEach(BuddyPersonBrowseChrome.affinityTags(for: item.profile), id: \.self) { tag in
                PlatformCaptionBadge(title: tag, chrome: .material)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(PlatformMetrics.captionBadgeInset)
        .colorScheme(.dark)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var paidAvailabilityTrailing: some View {
        if BuddyPersonBrowseChrome.isPaid(item) {
            let title = BuddyPersonBrowseChrome.isAvailablePaid(item)
                ? BuddyDetailCopy.available
                : BuddyDetailCopy.unavailable
            let tint = BuddyPersonBrowseChrome.isAvailablePaid(item)
                ? PlatformStatus.success
                : PlatformStatus.warning
            PlatformMediaCaptionBadge(title: title, tint: tint)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

/// 图下信息
struct BuddyPersonBrowseInfo: View {
    let profile: BuddyProfile
    let metaLine: String
    var density: BuddyPersonBrowseDensity = .grid
    var intentHit = false
    var titleFont: Font? = nil
    var metaFont: Font? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var resolvedTitleFont: Font {
        titleFont ?? (density == .hero ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
    }

    private var resolvedMetaFont: Font {
        metaFont ?? (density == .hero ? .subheadline : .caption)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.hairlineSpacing) {
                Text(profile.nickname)
                    .font(resolvedTitleFont)
                    .foregroundStyle(.primary)
                    .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
                if density == .hero {
                    Text(profile.gender.symbol)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(profile.gender.tint)
                        .accessibilityHidden(true)
                    if intentHit {
                        PlatformCaptionBadge(title: BuddyBrowseCopy.intentMatchBadge, chrome: .tint(.accentColor))
                    }
                }
            }

            if !metaLine.isEmpty {
                Text(metaLine)
                    .font(resolvedMetaFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Hero 图下 CTA：与详情底栏同词（联系用 `peerContactActionTitle`；陪玩用「预约」）
struct BuddyPersonBrowseAction: View {
    let item: DiscoverBuddyItem
    var contactActionTitle = BuddyBrowseCopy.chatAction
    var controlSize: ControlSize = .large
    var onAction: () -> Void

    var body: some View {
        Group {
            if BuddyPersonBrowseChrome.isPaid(item) {
                Button(
                    item.inviteEnabled ? BuddyDetailCopy.quickBook : BuddyDetailCopy.bookUnavailable,
                    action: onAction
                )
                .activityPrimaryCTA(controlSize: controlSize)
                .disabled(!item.inviteEnabled)
                .accessibilityHint(BuddyDetailCopy.bookAccessibilityHint)
            } else {
                Button(contactActionTitle, action: onAction)
                    .activityPrimaryCTA(controlSize: controlSize)
                    .accessibilityHint(BuddyDetailCopy.greetAccessibilityHint)
            }
        }
        .layoutPriority(1)
    }
}
