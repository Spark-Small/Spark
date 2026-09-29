//
//  WalletPassFaceChrome.swift
//  坐标系
//
//  长条凭证与展开票面共用：边距、顶栏、底栏操作。
//

import SwiftUI

// MARK: - Shared chrome（长条凭证与展开票面共用）

/// 与长条凭证同一套边距，保证展开票面顶栏 / 地点带视觉对齐。
enum WalletPassChromePadding {
    static var horizontal: CGFloat { PlatformMetrics.walletPassChromeInset }
    /// 垂直内边距 = Form 行微调量（由系统列表垂直 margin 推导）
    static var vertical: CGFloat { PlatformMetrics.formRowVerticalPadding }
    static var stackSpacing: CGFloat { PlatformMetrics.sectionSubtitleSpacing }
}

/// 顶栏：左标题/副文 · 右日程（字阶对齐详情 Form：主文 body / 副文 subheadline）
struct WalletPassFaceHeaderRow: View {
    let content: WalletPassFaceContent
    var titleLineLimit: Int = 1

    private var hasSchedule: Bool {
        !content.headerLabel.isEmpty || !content.headerValue.isEmpty
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.cardInfoSpacing) {
            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                Text(content.logoText)
                    .font(WalletPassTypography.logoText)
                    .foregroundStyle(.primary)
                    .lineLimit(titleLineLimit)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !content.subtitleText.isEmpty {
                    Text(content.subtitleText)
                        .font(WalletPassTypography.logoMeta)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(0)

            if hasSchedule {
                VStack(alignment: .trailing, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                    Text(schedulePrimary)
                        .font(WalletPassTypography.headerLabel)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if !scheduleSecondary.isEmpty {
                        Text(scheduleSecondary)
                            .font(WalletPassTypography.headerValue)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(scheduleAccessibilityLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var schedulePrimary: String {
        if !content.headerLabel.isEmpty { return content.headerLabel }
        return content.headerValue
    }

    private var scheduleSecondary: String {
        content.headerLabel.isEmpty ? "" : content.headerValue
    }

    private var scheduleAccessibilityLabel: String {
        [content.headerLabel, content.headerValue]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "，")
    }
}

/// 底栏：地点摘要 + 可选 glass 操作（无标签 / 无按钮时不占位）
struct WalletPassFaceFooterRow: View {
    let content: WalletPassFaceContent
    var onNavigate: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil
    var onOpenDetail: (() -> Void)? = nil
    var locationLineLimit: Int = 1

    private var showsLocationLabel: Bool {
        !content.locationText.isEmpty && !content.locationLabel.isEmpty
    }

    private var showsLocationValue: Bool {
        !content.locationText.isEmpty
    }

    private var trailingSlotCount: Int {
        var count = 0
        if content.showsDetailButton, onOpenDetail != nil { count += 1 }
        if content.showsMessageButton, onMessage != nil { count += 1 }
        if content.showsNavigateButton, onNavigate != nil { count += 1 }
        return count
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.cardInfoSpacing) {
            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                if showsLocationLabel {
                    Text(content.locationLabel)
                        .font(WalletPassTypography.fieldLabel)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if showsLocationValue {
                    Text(content.locationText)
                        .font(showsLocationLabel ? WalletPassTypography.fieldValue : WalletPassTypography.logoMeta)
                        .foregroundStyle(showsLocationLabel ? Color.primary : Color.secondary)
                        .lineLimit(locationLineLimit)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if trailingSlotCount > 0 {
                footerActions
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var footerActions: some View {
        HStack(spacing: PlatformMetrics.sectionSubtitleSpacing) {
            if content.showsDetailButton, let onOpenDetail {
                ActivityDetailControls.GlassIconButton(
                    systemImage: "info.circle",
                    accessibilityLabel: "活动详情",
                    action: onOpenDetail
                )
            }
            if content.showsMessageButton, let onMessage {
                ActivityDetailControls.GlassCapsuleButton(
                    title: "聊天",
                    accessibilityLabel: "联系陪玩",
                    action: onMessage
                )
            }
            if content.showsNavigateButton, let onNavigate {
                ActivityDetailControls.GlassCapsuleButton(
                    title: "导航",
                    accessibilityLabel: ActivityDetailCopy.navigationAction,
                    action: onNavigate
                )
            }
        }
    }
}
