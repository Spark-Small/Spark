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
    /// 发现类列表页（活动、搭子）
    static var groupedPage: Color { Color(.systemGroupedBackground) }
    /// 内容流页（社区、详情正文）
    static var canvas: Color { Color(.systemBackground) }
    /// 分组页上的卡片（活动列表卡、详情信息块）
    static var elevated: Color { Color(.secondarySystemGroupedBackground) }
    /// 白底详情页上的信息块（社区正文等 canvas 场景）
    static var groupedBlock: Color { Color(.secondarySystemBackground) }
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

/// 域操作色 — 仅用于明确指定的主转化按钮
enum PlatformAction {
    /// 坐标系品牌色 — App Icon 四叶草紫瓣（petal-06 / 信封印章）；Tab tint、主 CTA、引导页强调。
    static var cloverPurple: Color {
        Color(.displayP3, red: 0.58228, green: 0.46771, blue: 0.84753)
    }

    /// 与 `cloverPurple` 同值；文档与语义化引用优先用此名。
    static var brandAccent: Color { cloverPurple }
}
