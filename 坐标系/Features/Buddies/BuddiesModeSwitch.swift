//
//  BuddiesModeSwitch.swift
//  坐标系
//
//  顶栏对齐活动：标题菜单切模式；Trailing 搜索 + 筛选（预约在「我的」）。
//

import SwiftUI

/// 与 `ActivityBrowseCategoryTitleMenu` 同形态：大标题菜单切换免费 / 预约。
struct BuddiesModeTitleMenu: View {
    @Binding var kind: BuddyKind

    var body: some View {
        Picker("模式", selection: $kind) {
            ForEach(BuddyKind.allCases) { option in
                Label(option.stageTitle, systemImage: option.systemImage)
                    .tag(option)
            }
        }
        .pickerStyle(.inline)
    }
}

struct BuddiesModeSwitchToolbar: ToolbarContent {
    var hasActiveFilters: Bool
    var hasActiveSearch: Bool
    var filterAccessibilityValue: String
    var onSearch: () -> Void
    var onFilter: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("搜索", systemImage: "magnifyingglass") {
                onSearch()
            }
            .symbolVariant(hasActiveSearch ? .fill : .none)
            .accessibilityHint("搜索昵称、兴趣或擅长")
            .accessibilityValue(hasActiveSearch ? "已输入关键词" : "未搜索")

            Button(
                hasActiveFilters ? "筛选（已启用）" : "筛选",
                systemImage: "line.3.horizontal.decrease"
            ) {
                onFilter()
            }
            .symbolVariant(hasActiveFilters ? .fill : .none)
            .accessibilityHint("打开筛选：地区、性别、距离、兴趣、排序")
            .accessibilityValue(filterAccessibilityValue)
        }
    }
}

#Preview {
    struct Host: View {
        @State private var kind = BuddyKind.free
        var body: some View {
            NavigationStack {
                Text(kind.stageTitle)
                    .platformTabRootScrollChrome(title: kind.stageTitle)
                    .platformTabRootTitleMenu {
                        BuddiesModeTitleMenu(kind: $kind)
                    }
                    .platformTabRootToolbar {
                        BuddiesModeSwitchToolbar(
                            hasActiveFilters: false,
                            hasActiveSearch: false,
                            filterAccessibilityValue: "上海",
                            onSearch: {},
                            onFilter: {}
                        )
                    }
            }
        }
    }
    return Host()
}
