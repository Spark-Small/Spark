//
//  PlatformContentUnavailableChrome.swift
//  坐标系
//
//  页面级空态放置：铺满导航内容区，交给系统 ContentUnavailableView 垂直居中。
//

import SwiftUI

extension View {
    /// 页面级空态：铺满可用区域（勿把 `ContentUnavailableView` 塞进 List 行 / ScrollView 首行导致顶对齐）。
    func platformContentUnavailablePageChrome() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
