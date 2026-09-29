//
//  ActivityDetailControls.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

enum ActivityDetailControls {
    /// 官方圆形 glass 图标：闹钟 / 导航 / 私信 / 关闭 / 发送
    struct GlassIconButton: View {
        let systemImage: String
        var accessibilityLabel: String
        var prominent = false
        var role: ButtonRole?
        var action: () -> Void

        var body: some View {
            Button(role: role, action: action) {
                Image(systemName: systemImage)
            }
            .activityGlassIcon(prominent: prominent)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    /// 活动日历切换：与详情时间行同款 glass / glassProminent 着色。
    struct CalendarGlassButton: View {
        var isScheduled: Bool
        var action: () -> Void

        var body: some View {
            GlassIconButton(
                systemImage: ActivityCalendar.Symbol.systemName(isScheduled: isScheduled),
                accessibilityLabel: isScheduled
                    ? ActivityDetailCopy.calendarRemoveAction
                    : ActivityDetailCopy.calendarAction,
                prominent: isScheduled,
                action: action
            )
        }
    }

    /// Sheet 导航栏日历：标准图标按钮（已加入用 accent 着色，与详情状态一致）。
    struct CalendarToolbarButton: View {
        var isScheduled: Bool
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: ActivityCalendar.Symbol.systemName(isScheduled: isScheduled))
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(isScheduled ? Color.accentColor : Color.primary)
            .accessibilityLabel(
                isScheduled
                    ? ActivityDetailCopy.calendarRemoveAction
                    : ActivityDetailCopy.calendarAction
            )
            .accessibilityHint("加入或移除本场活动的日历提醒")
        }
    }

    /// 官方 glass 胶囊（纯文案）：对齐发现卡「参加」主 CTA
    struct GlassCapsuleButton: View {
        let title: String
        var accessibilityLabel: String? = nil
        var controlSize: ControlSize = .regular
        var action: () -> Void

        var body: some View {
            Button(title, action: action)
                .activityPrimaryCTA(controlSize: controlSize)
                .accessibilityLabel(accessibilityLabel ?? title)
        }
    }

    /// 菜单触发 — label 勿再包 Button
    struct GlassIconMenu<Content: View>: View {
        var systemImage = "ellipsis"
        var accessibilityLabel = "更多"
        @ViewBuilder var content: () -> Content

        var body: some View {
            Menu {
                content()
            } label: {
                Image(systemName: systemImage)
            }
            .compositingGroup()
            .activityGlassIcon(prominent: false)
            .accessibilityLabel(accessibilityLabel)
        }
    }
}

extension View {
    /// 详情底栏主 CTA：系统 `buttonSizing(.flexible)` 拉满可用宽度
    func activityDetailBottomPrimaryCTA() -> some View {
        activityPrimaryCTA(controlSize: .large)
            .buttonSizing(.flexible)
    }

    /// 详情底栏次要 CTA：与主 CTA 同宽槽位
    func activityDetailBottomSecondaryCTA() -> some View {
        activitySecondaryCTA(controlSize: .large)
            .buttonSizing(.flexible)
    }
}

/// 详情页底部双 CTA 栏：搭子 / 陪玩 / 活动详情共用布局
struct DetailBottomActionBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: PlatformMetrics.detailBottomBarSpacing) {
            content()
        }
        .activityDetailBottomBarChrome()
    }
}
