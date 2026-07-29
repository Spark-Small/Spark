//
//  BuddyDiscoverCard.swift
//  坐标系
//
//  选人 Hero 底栏：同好「聊天」；陪玩「邀约」。
//

import SwiftUI

/// 舞台底部信息区
struct BuddyDiscoverCard: View {
    let item: DiscoverBuddyItem
    var enablesOpenTap = true
    var onOpen: () -> Void = {}
    var onGreet: () -> Void
    var onInvite: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var profile: BuddyProfile { item.profile }

    private var isPaid: Bool {
        if case .paid = item { return true }
        return false
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            infoColumn
            actionsColumn
        }
        .padding(.vertical, PlatformMetrics.cardInfoSpacing)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private var accessibilitySummary: String {
        if case .paid(let companion) = item {
            return "\(profile.nickname)，\(companion.priceText)，\(item.cardHobbyLine)"
        }
        return "\(profile.nickname)，\(item.cardHobbyLine)"
    }

    @ViewBuilder
    private var infoColumn: some View {
        let column = VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            Text(profile.nickname)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))

            if case .paid(let companion) = item {
                Text(companion.isAvailable ? companion.priceText : "暂不可约")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(item.cardHobbyLine)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))

                Text(paidMetaLine(companion))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text(item.cardHobbyLine)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))

                Text(freeMetaLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .colorScheme(.dark)

        if enablesOpenTap {
            Button(action: onOpen) { column }
                .buttonStyle(.plain)
        } else {
            column
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var actionsColumn: some View {
        if isPaid {
            Button(item.inviteEnabled ? "邀约" : "暂不可约", action: onInvite)
                .font(.subheadline.weight(.semibold))
                .activityPrimaryCTA(controlSize: .regular)
                .disabled(!item.inviteEnabled)
        } else {
            Button("聊天", action: onGreet)
                .font(.subheadline.weight(.semibold))
                .activityPrimaryCTA(controlSize: .regular)
        }
    }

    private var freeMetaLine: String {
        [
            profile.distanceText,
            "\(profile.age)岁",
            profile.gender.symbol,
            item.cardStatusLine
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    private func paidMetaLine(_ companion: PaidCompanion) -> String {
        [
            String(format: "%.1f 分", companion.rating),
            "\(companion.orderCount) 单",
            item.cardStatusLine
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}

#Preview("同好底栏") {
    ZStack(alignment: .bottom) {
        Color.gray
        BuddyDiscoverCard(
            item: .free(SampleData.circleBuddies[0]),
            onGreet: {},
            onInvite: {}
        )
    }
    .frame(height: 220)
}

#Preview("陪玩底栏") {
    ZStack(alignment: .bottom) {
        Color.gray
        BuddyDiscoverCard(
            item: .paid(SampleData.paidCompanions[0]),
            onGreet: {},
            onInvite: {}
        )
    }
    .frame(height: 220)
}
