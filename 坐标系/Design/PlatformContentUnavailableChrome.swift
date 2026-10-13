//
//  PlatformContentUnavailableChrome.swift
//  坐标系
//
//  空态放置：纯空页铺满导航区；Scroll 货架内嵌随滚撑高居中。
//  **禁止**对空态再用 List/Scroll `.overlay` 钉死视口。
//

import SwiftUI

extension View {
    /// 纯空页：铺满导航内容区，交给系统 ContentUnavailableView 垂直居中。
    /// 用于 `Group { if empty { … } else { List } }` 替换路径。
    func platformContentUnavailablePageChrome() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Scroll 货架 / 社交主页内嵌空态：相对容器撑高后区内居中，**随内容滚动**。
    /// 勿叠在 Scroll `.overlay`；勿做 Scroll 首子视图顶对齐。
    func platformScrollEmbeddedEmptyChrome() -> some View {
        containerRelativeFrame(.vertical) { height, _ in
            max(height * 0.55, 280)
        }
        .frame(maxWidth: .infinity)
    }
}
