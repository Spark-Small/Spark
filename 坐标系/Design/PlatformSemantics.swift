//
//  PlatformSemantics.swift
//  坐标系
//
//  仅封装 Apple 平台语义 API（系统色 / Dynamic Type / 材质 / Glass），
//  不引入品牌色或自定义 HSB。
//
//  拆分索引：
//  - PlatformMetrics.swift — 间距 / 圆角 token
//  - PlatformListAvatar.swift — 头像组件 + DynamicTypeSize 头像边长
//  - PlatformToolbarChrome.swift — Photos 式顶栏
//  - PlatformConversationListChrome.swift — 消息 / 好友 List 几何
//  - PlatformActivityChrome.swift — CTA / glass / 角标
//  - PlatformFeedback.swift — Alert / 轻量触觉
//

import SwiftUI

enum PlatformSurface {
    /// 系统分组底（Form / insetGrouped）；语义色，非品牌色。
    static var groupedPage: Color { Color(.systemGroupedBackground) }
    /// 系统内容底（`systemBackground`）；需要显式铺底时用，Tab 根优先交给系统默认。
    static var canvas: Color { Color(.systemBackground) }
    /// 分组页上的卡片（活动列表卡、详情信息块）
    static var elevated: Color { Color(.secondarySystemGroupedBackground) }
    /// 白底详情页上的信息块（社区正文等 canvas 场景）
    static var groupedBlock: Color { Color(.secondarySystemBackground) }
    /// 系统三级填充（占位底、未选中 chip）
    static var tertiaryFill: Color { Color(.tertiarySystemFill) }
    /// 系统强调色轻底（图标盘 / 海报占位）
    static var accentSoftFill: Color { Color.accentColor.opacity(0.14) }
    static var bar: Material { .bar }
    static var thin: Material { .thinMaterial }
}

/// 系统状态色 — SwiftUI 内置语义色，非品牌自定义
enum PlatformStatus {
    static var success: Color { .green }
    static var warning: Color { .orange }
    static var danger: Color { .red }
    static var accent: Color { .accentColor }
}

/// 域操作色 — 跟随系统 AccentColor（官方原色）；不再使用自定义四叶草紫。
enum PlatformAction {
    /// 系统强调色（Asset Catalog `AccentColor` / 环境 tint）。
    static var brandAccent: Color { .accentColor }

    /// 历史别名；等价于 `brandAccent`（系统原色）。
    static var cloverPurple: Color { brandAccent }
}
