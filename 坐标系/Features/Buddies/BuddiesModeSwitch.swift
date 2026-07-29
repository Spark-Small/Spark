//
//  BuddiesModeSwitch.swift
//  坐标系
//
//  顶栏右侧：单个「陪玩」文字按钮；默认同好，点按进入陪玩，再点返回。
//

import SwiftUI

/// 默认同好；右侧仅「陪玩」文字开关
struct BuddiesModeSwitchToolbar: ToolbarContent {
    @Binding var kind: BuddyKind

    private var isPaid: Bool { kind == .paid }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("陪玩") {
                kind = isPaid ? .free : .paid
            }
            .fontWeight(isPaid ? .semibold : .regular)
            .accessibilityLabel("陪玩")
            .accessibilityValue(isPaid ? "已打开" : "未打开")
            .accessibilityHint(isPaid ? "再点一次返回同好" : "切换到陪玩")
            .accessibilityAddTraits(isPaid ? .isSelected : [])
        }
    }
}

#Preview {
    struct Host: View {
        @State private var kind = BuddyKind.free
        var body: some View {
            NavigationStack {
                Text(kind == .paid ? "陪玩" : "同好")
                    .toolbar { BuddiesModeSwitchToolbar(kind: $kind) }
            }
        }
    }
    return Host()
}
