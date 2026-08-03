//
//  BuddyBrowseShelves.swift
//  坐标系
//
//  搭子发现货架：情境活动卡（Soul→活动）· 兴趣话题条 · Discord 式语音厅频道卡。
//  布局复用 DiscoverBrowseSection / DiscoverHorizontalRail / PlatformContinueCard。
//

import SwiftUI

// MARK: - 情境 → 活动卡

enum BuddySituationCatalog {
    /// 附近可组局的活动：兴趣重合优先，再按时间；上限 `limit`
    static func activities(
        from model: ActivitiesModel,
        interests: [String] = BuddyMatchScorer.myInterests,
        limit: Int = 8
    ) -> [Activity] {
        let upcoming = model.activities
            .filter { !$0.isLifecycleEnded }
            .sorted { $0.date < $1.date }

        guard !upcoming.isEmpty else { return [] }

        let matched = upcoming.filter { activity in
            interests.contains { interest in
                activity.title.localizedCaseInsensitiveContains(interest)
                    || activity.category.title.localizedCaseInsensitiveContains(interest)
                    || activity.tags.contains {
                        $0.localizedCaseInsensitiveContains(interest)
                    }
            }
        }

        var seen = Set<Activity.ID>()
        var ordered: [Activity] = []
        for activity in matched + upcoming {
            guard seen.insert(activity.id).inserted else { continue }
            ordered.append(activity)
            if ordered.count >= limit { break }
        }
        return ordered
    }

    static func badge(for activity: Activity) -> String {
        let hours = activity.date.timeIntervalSinceNow / 3600
        if hours < 6 { return "马上开始" }
        if Calendar.current.isDateInToday(activity.date) { return "今晚可去" }
        if Calendar.current.isDateInTomorrow(activity.date) { return "明天" }
        return activity.category.title
    }

    static func metaLine(for activity: Activity, isJoined: Bool) -> String {
        var parts: [String] = [
            Formatters.activityEventTime(from: activity.date),
            activity.location
        ]
        if isJoined {
            parts.append("已参加")
        } else if activity.isFree {
            parts.append("免费")
        } else {
            parts.append(activity.fee)
        }
        return parts.joined(separator: " · ")
    }
}

/// 同好页顶：情境横滑 = 迷你活动卡（点击进活动详情 Zoom）
struct BuddySituationRail: View {
    let activities: [Activity]
    var zoomNamespace: Namespace.ID
    var isJoined: (Activity.ID) -> Bool
    var onJoin: (Activity) -> Void

    var body: some View {
        DiscoverBrowseSection(
            title: "想找人一起去",
            subtitle: "情境即活动，点进去找局或找同去的人"
        ) {
            DiscoverHorizontalRail {
                ForEach(activities) { activity in
                    PlatformContinueCard(
                        activityID: activity.id,
                        zoomNamespace: zoomNamespace,
                        photo: activity.coverPhoto,
                        title: activity.title,
                        timeLine: BuddySituationCatalog.badge(for: activity),
                        metaLine: BuddySituationCatalog.metaLine(
                            for: activity,
                            isJoined: isJoined(activity.id)
                        ),
                        isJoined: isJoined(activity.id),
                        isFull: activity.isFull,
                        onJoin: { onJoin(activity) }
                    )
                    .platformContinueRailFrame()
                }
            }
        }
    }
}

// MARK: - 话题 / 兴趣

/// 兴趣话题 chips：点选写入 `BuddyFilter.hobby`（与筛选 Sheet 同源）
struct BuddyTopicInterestBar: View {
    @Binding var hobby: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            DiscoverSectionTitleRow(
                title: "兴趣话题",
                subtitle: "点选快速筛选同好"
            )

            PlatformFilterChipBar {
                PlatformFilterChipButton(
                    title: "全部",
                    systemImage: "square.grid.2x2",
                    isSelected: hobby == nil
                ) {
                    hobby = nil
                }

                ForEach(BuddyHobbyOption.allCases) { option in
                    PlatformFilterChipButton(
                        title: option.rawValue,
                        systemImage: option.systemImage,
                        isSelected: hobby == option.rawValue
                    ) {
                        hobby = (hobby == option.rawValue) ? nil : option.rawValue
                    }
                }
            }
        }
    }
}

// MARK: - Discord 式语音厅频道卡

/// 陪玩中段：频道感横卡（厅名 · 麦位头像 · 在听 · 进厅），不用竖海报
struct BuddyVoiceChannelCard: View {
    let hall: VoiceHall
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.minContentGap) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(hall.isLive ? PlatformStatus.success : .secondary)
                        .accessibilityHidden(true)

                    Text(hall.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(hall.isLive ? "直播中" : "休息中")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hall.isLive ? PlatformStatus.success : .secondary)
                }

                Text(hall.topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                    micAvatarStack

                    Text(hall.audienceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text("进厅")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.tint.opacity(0.14), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(PlatformMetrics.contentInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
            .overlay {
                PlatformMetrics.cardShape
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(hall.title)，\(hall.topic)，\(hall.audienceText)")
        .accessibilityHint("进入语音厅")
    }

    private var micAvatarStack: some View {
        HStack(spacing: -8) {
            ForEach(Array(hall.onMicNicknames.prefix(4).enumerated()), id: \.offset) { _, name in
                PlatformListAvatarView(name: name, side: 28)
                    .overlay {
                        Circle().strokeBorder(PlatformSurface.elevated, lineWidth: 2)
                    }
            }
            if hall.onMicNicknames.count > 4 {
                Text("+\(hall.onMicNicknames.count - 4)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 10)
            }
        }
        .accessibilityHidden(true)
    }
}

struct BuddyVoiceChannelRail: View {
    let halls: [VoiceHall]
    var onOpen: (VoiceHall) -> Void

    var body: some View {
        DiscoverBrowseSection(
            title: "语音厅",
            subtitle: "正在开麦的厅，点进厅听麦或预约麦上的人"
        ) {
            DiscoverHorizontalRail {
                ForEach(halls) { hall in
                    BuddyVoiceChannelCard(hall: hall) {
                        onOpen(hall)
                    }
                    .platformContinueRailFrame()
                }
            }
        }
    }
}
