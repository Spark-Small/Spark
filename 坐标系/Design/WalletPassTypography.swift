//
//  WalletPassTypography.swift
//  坐标系
//
//  票面字阶与 Dynamic Type 行数（对齐详情 Form / Wallet 密度）。
//

import SwiftUI

// MARK: - Typography（票面顶栏对齐详情 Form §3.3；字段区对齐 Wallet primary / auxiliary）

/// App 内票面字阶：顶栏跟详情 Form；字段 label/value 跟 Wallet 密度；主字段可大一级。
enum WalletPassTypography {
    /// 详情 Form 主文：活动名 / 凭证标题
    static var logoText: Font { .body }
    /// 详情 Form 副文：品牌、人数、日程副行
    static var logoMeta: Font { .subheadline }
    /// 详情 Form 主文：星期 + 时刻（展开票面右上）
    static var headerLabel: Font { .body }
    /// 详情 Form 副文：月日（展开票面右上）
    static var headerValue: Font { .subheadline }
    /// 行程票顶栏：阶段 + 日程（Form 副文档，强于 fieldLabel）
    static var scheduleMeta: Font { .subheadline }
    /// 行程票顶栏：参与者 / 版型标签（最弱 meta）
    static var participantMeta: Font { .caption2 }
    static var kindBadge: Font { .caption2.weight(.semibold) }
    /// Wallet auxiliary label（场馆、座位、费用等）
    static var fieldLabel: Font { .caption2.weight(.medium) }
    /// Wallet auxiliary value
    static var fieldValue: Font { .footnote.weight(.semibold) }
    /// Wallet primaryFields（展开票面等场景；行程页主信息改用 heroFieldValue）
    static var primaryFieldValue: Font { .title3.weight(.semibold) }
    /// 行程票唯一主信息行（全宽，长短文案统一字阶）
    static var heroFieldValue: Font { .body.weight(.semibold) }
    /// 字段区中心符号（辅助图形，不抢主信息）
    static var centerSymbol: Font { .body.weight(.semibold) }
    /// 中部细则（近 backFields 密度）
    static var notesBody: Font { .footnote }
    static var notesSection: Font { .caption2.weight(.semibold) }
}

/// 票面 Dynamic Type：与 `DiscoverAccessibility` 同原则，常规字阶保密度，无障碍放开行数。
enum WalletPassAccessibility {
    static func titleLineLimit(for size: DynamicTypeSize) -> Int? {
        DiscoverAccessibility.titleLineLimit(for: size)
    }

    static func scheduleLineLimit(for size: DynamicTypeSize) -> Int? {
        DiscoverAccessibility.bodyLineLimit(for: size, regular: 2)
    }

    static func participantLineLimit(for size: DynamicTypeSize) -> Int? {
        DiscoverAccessibility.metaLineLimit(for: size)
    }

    static func kindBadgeLineLimit(for size: DynamicTypeSize) -> Int? {
        DiscoverAccessibility.metaLineLimit(for: size)
    }

    static func fieldLabelLineLimit(for size: DynamicTypeSize) -> Int? {
        DiscoverAccessibility.metaLineLimit(for: size)
    }

    static func heroValueLineLimit(for size: DynamicTypeSize) -> Int? {
        DiscoverAccessibility.metaLineLimit(for: size)
    }

    static func fieldValueLineLimit(
        for size: DynamicTypeSize,
        primary: Bool
    ) -> Int? {
        primary
            ? DiscoverAccessibility.bodyLineLimit(for: size, regular: 2)
            : DiscoverAccessibility.metaLineLimit(for: size)
    }

    static func allowsMinimumScaleFactor(for size: DynamicTypeSize) -> Bool {
        !size.isAccessibilitySize
    }
}
