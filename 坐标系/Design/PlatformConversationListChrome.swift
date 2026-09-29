//
//  PlatformConversationListChrome.swift
//  坐标系
//
//  消息 / 好友 List 几何：subtitleCell 探针 + plain List chrome。
//

import SwiftUI
import UIKit

/// 行程等「卡入 List」行边距：几何收在 Design，Features 只调此 API
enum PlatformCardListRow {
    static var insets: EdgeInsets {
        EdgeInsets(
            top: PlatformMetrics.sectionHeaderSpacing,
            leading: PlatformMetrics.contentInset,
            bottom: PlatformMetrics.sectionHeaderSpacing,
            trailing: PlatformMetrics.contentInset
        )
    }
}

/// insetGrouped 内长条凭证行：水平交给系统分组页边；垂直用 subtitleCell 行 margin。
enum PlatformWalletPassListRow {
    static var insets: EdgeInsets {
        let vertical = PlatformConversationListRow.verticalInset
        return EdgeInsets(top: vertical, leading: 0, bottom: vertical, trailing: 0)
    }
}

/// 消息 List 行几何：默认值直接取自 Apple `UIListContentConfiguration.subtitleCell()`（及 plain `UITableView` 探针）。
enum PlatformConversationListRow {
    private static var configuration: UIListContentConfiguration {
        UIListContentConfiguration.subtitleCell()
    }

    /// 水平页边 = subtitleCell leading ∩ 表/导航栏 layout margins（`PlatformMetrics.contentInset`）
    static var horizontalInset: CGFloat { PlatformMetrics.contentInset }

    /// 行垂直 inset = subtitleCell 上下 layout margin
    static var verticalInset: CGFloat {
        let margins = configuration.directionalLayoutMargins
        let systemVertical = max(margins.top, margins.bottom)
        return systemVertical > 0
            ? systemVertical
            : UIFont.preferredFont(forTextStyle: .body).lineHeight
    }

    /// 垂直密度；水平由 `platformConversationListChrome` 的 contentMargins 提供
    static var insets: EdgeInsets {
        let vertical = verticalInset
        return EdgeInsets(top: vertical, leading: 0, bottom: vertical, trailing: 0)
    }

    /// 字母分节头垂直 = subtitleCell 上下 layout margin
    static var sectionHeaderInsets: EdgeInsets {
        EdgeInsets(top: verticalInset, leading: 0, bottom: verticalInset, trailing: 0)
    }

    /// List 分节间距 = 系统 `UITableView.sectionHeaderTopPadding`
    static var listSectionSpacing: CGFloat { PlatformMetrics.sectionSpacing }

    /// 图↔文 = `subtitleCell.imageToTextPadding`
    static var imageToTextPadding: CGFloat {
        let padding = configuration.imageToTextPadding
        return padding > 0 ? padding : PlatformMetrics.minContentGap
    }

    /// 主↔副文 = `subtitleCell.textToSecondaryTextVerticalPadding`
    static var textToSecondarySpacing: CGFloat {
        let padding = configuration.textToSecondaryTextVerticalPadding
        return padding > 0 ? padding : PlatformMetrics.sectionSubtitleSpacing
    }

    /// 含头像行 ↔ 下方独立内容块（配图等）= subtitleCell 行垂直 margin
    static var rowToContentSpacing: CGFloat { verticalInset }

    /// 列表头像边长 = `ImageProperties.standardDimension`
    static var imageSide: CGFloat {
        let side = UIListContentConfiguration.ImageProperties.standardDimension
        return side > 0 ? side : PlatformListAvatar.standardPointSize()
    }
}

extension View {
    /// 消息模块：隐藏 List / Form 行与分节分隔线
    func platformMessagesSeparatorsHidden() -> some View {
        self
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
    }

    /// 消息 / 好友共用 List 容器：plain + Apple subtitleCell 测得的水平页边与分节距
    func platformConversationListChrome() -> some View {
        self
            .listStyle(.plain)
            .platformMessagesSeparatorsHidden()
            .listSectionSpacing(PlatformConversationListRow.listSectionSpacing)
            .contentMargins(.horizontal, PlatformConversationListRow.horizontalInset, for: .scrollContent)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background(PlatformSurface.canvas)
    }

    /// 消息页级水平边距（ScrollView / 线程）
    func platformMessagePageMargins() -> some View {
        contentMargins(.horizontal, PlatformConversationListRow.horizontalInset, for: .scrollContent)
    }

    func platformMessagePagePadding() -> some View {
        padding(.horizontal, PlatformConversationListRow.horizontalInset)
    }

    /// 行垂直密度 = subtitleCell layout margins；放在 swipeActions 之后。水平页边见 `platformConversationListChrome()`。
    func platformConversationListRowChrome() -> some View {
        self
            .listRowInsets(PlatformConversationListRow.insets)
            .platformMessagesSeparatorsHidden()
    }

    /// 好友字母分节头垂直密度
    func platformConversationSectionHeaderChrome() -> some View {
        self
            .listRowInsets(PlatformConversationListRow.sectionHeaderInsets)
            .platformMessagesSeparatorsHidden()
    }

    /// 「我的」活动 / 陪玩长条凭证 List 行：系统行高边距，无手写 inset。
    func platformWalletPassCredentialRow() -> some View {
        self
            .listRowInsets(PlatformWalletPassListRow.insets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .navigationLinkIndicatorVisibility(.hidden)
    }

    /// 二级页隐藏 Tab 底栏。
    func platformHiddenTabBar() -> some View {
        toolbarVisibility(.hidden, for: .tabBar)
    }
}

/// 消息二级页分区头：与好友列表字母分节头同密度
struct PlatformMessagesSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .platformConversationSectionHeaderChrome()
    }
}
