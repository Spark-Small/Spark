//
//  ActivityCardStyle.swift
//  坐标系
//
//  活动卡片共享样式：状态文案表 + 主操作 + Hero 壳。
//  发现表面：内容可变，chrome（动词 / 角标 / 字阶）由本文件与 Platform* 决定。
//

import SwiftUI

// MARK: - Status vocabulary（发现表面唯一出口）

/// 活动链路共用状态 / 动作文案（发现 · 详情 · 反馈）
enum ActivityCardStatus {
    static let joined = "已参加"
    static let join = "参加"
    static let joinFree = "免费参加"
    static let joinSuccess = "参加成功"
    static let joinConfirm = "确认参加"
    static let cancelJoin = "取消参加"
    static let full = "已满"
    static let almostFull = "快满"
    static let free = "免费"
    static let tonight = "今晚"
    static let openHint = "打开活动详情"
    static let fullWaitlistAnnounce = "已满，可加入候补"
    static let joinWaitlist = "加入候补"
    static let leaveWaitlist = "退出候补"
    static let waitlistSpotOpen = "候补名额已开放"
    /// 详情决策语境（比角标「已满」稍完整）
    static let fullVerbose = "名额已满"
    static let openGroupChat = "进群打招呼"
    static let shareActivity = "分享活动"
    static let favorite = "收藏"
    static let unfavorite = "取消收藏"
    static let refineContent = "完善活动说明"
    static let reportReceived = "已收到反馈"

    static func friendAlsoGoing(_ name: String) -> String { "\(name)也去" }

    static func spotsText(for activity: Activity, spaced: Bool = true) -> String {
        spotsText(full: activity.isFull, remaining: activity.remainingSpots, spaced: spaced)
    }

    static func spotsText(full: Bool, remaining: Int, spaced: Bool = true) -> String {
        if full { return Self.full }
        return spaced ? "剩 \(remaining) 席" : "剩\(remaining)席"
    }

    static func spotsLabel(full: Bool, almostFull: Bool, remaining: Int) -> String {
        if full { return fullVerbose }
        if almostFull { return "仅剩 \(remaining) 席" }
        return spotsText(full: false, remaining: remaining, spaced: true)
    }

    static func joinPrimaryLabel(free: Bool) -> String {
        free ? joinFree : join
    }

    /// 封面左上角标：紧迫 / 社交 / 属性；「已参加」由主操作 chip 承担，不进角标
    @MainActor
    static func captionBadge(
        for activity: Activity,
        fallback: String? = nil
    ) -> String? {
        if activity.isFull { return full }
        if let friend = ActivityRecommender.matchedFriends(for: activity).first {
            return friendAlsoGoing(friend)
        }
        if activity.isAlmostFull { return almostFull }
        if activity.isFree { return free }
        let hour = Calendar.current.component(.hour, from: activity.date)
        if Calendar.current.isDateInToday(activity.date), hour >= 17 {
            return tonight
        }
        return fallback
    }

    /// 热场横卡：地点 · 费用或剩余席位
    static func hotMetaLine(for activity: Activity) -> String {
        if activity.isAlmostFull || activity.isFull {
            return "\(activity.districtLabel) · \(spotsText(for: activity, spaced: true))"
        }
        let fee = activity.isFree ? free : activity.fee
        return "\(activity.districtLabel) · \(fee)"
    }

    /// 热场横卡角标
    @MainActor
    static func hotBadge(for activity: Activity) -> String? {
        captionBadge(for: activity, fallback: activity.category.shortTitle)
    }

    /// 列表大卡角标：仅紧迫态（已参加走 chip）
    static func urgencyBadge(isJoined: Bool, activity: Activity) -> (text: String, tint: Color)? {
        guard !isJoined, activity.isAlmostFull else { return nil }
        return (almostFull, PlatformStatus.warning)
    }

    static func openAccessibilityLabel(
        status: String? = nil,
        title: String,
        parts: String...
    ) -> String {
        ([status, title] + parts)
            .compactMap { $0?.nilIfEmpty }
            .joined(separator: "，")
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Primary action（发现表面唯一主操作）

/// 已参加：次要 glass 胶囊（与主 CTA 同家族，非独立材质块）
struct ActivityJoinedStatusChip: View {
    var controlSize: ControlSize = .regular
    var expandsHorizontally = false

    var body: some View {
        Button(ActivityCardStatus.joined) {}
            .activitySecondaryCTA(controlSize: controlSize)
            .frame(maxWidth: expandsHorizontally ? .infinity : nil)
            .disabled(true)
            .accessibilityLabel(ActivityCardStatus.joined)
    }
}

/// 参加 / 加入候补 / 已参加 — Featured、轨卡、列表大卡共用
struct ActivityPrimaryAction: View {
    var isJoined: Bool
    var isFull: Bool
    var controlSize: ControlSize = .regular
    var expandsHorizontally = false
    var onMedia = false
    var onJoin: (() -> Void)?

    var body: some View {
        if isJoined {
            ActivityJoinedStatusChip(
                controlSize: controlSize,
                expandsHorizontally: expandsHorizontally
            )
            .colorScheme(onMedia ? .dark : .light)
        } else if let onJoin {
            // 满员不禁用：主操作进入候补/详情（与 quickJoin 一致）
            Button(
                isFull ? ActivityCardStatus.joinWaitlist : ActivityCardStatus.join,
                action: onJoin
            )
            .activityPrimaryCTA(controlSize: controlSize)
            .frame(maxWidth: expandsHorizontally ? .infinity : nil)
        }
    }
}

/// 封面卡左上角紧迫角标
struct ActivityCardStatusBadge: View {
    let isJoined: Bool
    let activity: Activity

    var body: some View {
        if let badge = ActivityCardStatus.urgencyBadge(isJoined: isJoined, activity: activity) {
            PlatformMediaCaptionBadge(title: badge.text, tint: badge.tint)
        }
    }
}

// MARK: - Activity hero

/// 活动封面叠字卡（发现流）
struct ActivityHeroCard<Meta: View>: View {
    let activity: Activity
    var isJoined: Bool
    var layout: HeroMediaCardLayout
    var zoomNamespace: Namespace.ID? = nil
    var enablesOpenTap = true
    var onOpen: () -> Void
    var onJoin: (() -> Void)?
    @ViewBuilder var meta: () -> Meta

    private var statusCaption: String? {
        if isJoined { return ActivityCardStatus.joined }
        return ActivityCardStatus.urgencyBadge(isJoined: false, activity: activity)?.text
    }

    var body: some View {
        HeroMediaCard(
            layout: layout,
            title: activity.title,
            enablesOpenTap: enablesOpenTap && zoomNamespace == nil,
            accessibilityLabel: openAccessibilityLabel,
            onOpen: onOpen,
            cover: {
                coverMedia
            },
            meta: meta,
            status: {
                ActivityCardStatusBadge(isJoined: isJoined, activity: activity)
            },
            actions: {
                ActivityPrimaryAction(
                    isJoined: isJoined,
                    isFull: activity.isFull,
                    controlSize: .regular,
                    onJoin: onJoin
                )
            }
        )
    }

    private var openAccessibilityLabel: String {
        ActivityCardStatus.openAccessibilityLabel(
            status: statusCaption,
            title: activity.title,
            parts: Formatters.activityEventTime(from: activity.date),
            activity.location
        )
    }

    @ViewBuilder
    private var coverMedia: some View {
        if let zoomNamespace {
            ActivityZoomNavigationLink(
                activityID: activity.id,
                namespace: zoomNamespace
            ) {
                CommunityRemotePhoto(ref: activity.coverPhoto)
            }
            .accessibilityLabel(openAccessibilityLabel)
            .accessibilityHint(ActivityCardStatus.openHint)
        } else {
            CommunityRemotePhoto(ref: activity.coverPhoto)
        }
    }
}
