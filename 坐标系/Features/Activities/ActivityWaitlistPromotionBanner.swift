//
//  ActivityWaitlistPromotionBanner.swift
//  坐标系
//
//  候补名额开放：我的行程内的系统级提示条。
//

import SwiftUI

/// 候补可转正横条：标题 + 时间 + 操作同一卡片内（Design / Metrics，无裸魔法数）
struct ActivityWaitlistPromotionBanner: View {
    let activity: Activity
    var onOpen: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            Label(ActivityCardStatus.waitlistSpotOpen, systemImage: "ticket")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PlatformStatus.success)
                .labelStyle(.titleAndIcon)

            Text(activity.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(Formatters.activityEventTime(from: activity.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: PlatformMetrics.railCardSpacing) {
                Button("稍后", systemImage: "clock", action: onDismiss)
                    .activitySecondaryCTA(controlSize: .regular)
                    .frame(maxWidth: .infinity)

                Button(ActivityCardStatus.join, systemImage: "ticket", action: onOpen)
                    .activityPrimaryCTA(controlSize: .regular)
                    .frame(maxWidth: .infinity)
            }
            .buttonSizing(.flexible)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PlatformMetrics.contentInset)
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            ActivityCardStatus.openAccessibilityLabel(
                status: ActivityCardStatus.waitlistSpotOpen,
                title: activity.title,
                parts: Formatters.activityEventTime(from: activity.date)
            )
        )
    }
}

/// 我的行程：一条或多条候补晋升提示
struct ActivityWaitlistPromotionSection: View {
    let activities: [Activity]
    var onOpen: (Activity) -> Void
    var onDismiss: (Activity.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            ForEach(activities) { activity in
                ActivityWaitlistPromotionBanner(
                    activity: activity,
                    onOpen: { onOpen(activity) },
                    onDismiss: { onDismiss(activity.id) }
                )
            }
        }
    }
}
