//
//  BuddiesModeSwitch.swift
//  坐标系
//
//  顶栏右侧：搭子 / 陪玩单图标切换 + 筛选。
//

import SwiftUI

enum BuddiesCopy {
    static let rootTitle = "搭子"
}

struct BuddiesModeSwitchToolbar: ToolbarContent {
    @Binding var kind: BuddyKind
    var hasActiveFilters: Bool
    var filterAccessibilityValue: String
    var onFilter: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                kind = kind == .paid ? .free : .paid
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .accessibilityLabel(kind == .paid ? "陪玩" : "搭子")
            .accessibilityHint(kind == .paid ? "切换到搭子" : "切换到陪玩")

            Button(
                hasActiveFilters ? "筛选（已启用）" : "筛选",
                systemImage: "slider.horizontal.3"
            ) {
                onFilter()
            }
            .symbolVariant(hasActiveFilters ? .fill : .none)
            .accessibilityHint("打开筛选：地区、性别、距离、兴趣")
            .accessibilityValue(filterAccessibilityValue)
        }
    }
}

#Preview {
    struct Host: View {
        @State private var kind = BuddyKind.free
        var body: some View {
            NavigationStack {
                Text(kind == .paid ? "陪玩" : "搭子")
                    .platformTabRootScrollChrome(title: BuddiesCopy.rootTitle)
                    .platformTabRootToolbar {
                        BuddiesModeSwitchToolbar(
                            kind: $kind,
                            hasActiveFilters: false,
                            filterAccessibilityValue: "上海",
                            onFilter: {}
                        )
                    }
            }
        }
    }
    return Host()
}
