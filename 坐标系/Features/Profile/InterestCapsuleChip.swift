//
//  InterestCapsuleChip.swift
//  坐标系
//
//  喜好多选胶囊：系统 glass / bordered + capsule；选中用 Label checkmark（图文距系统）。
//

import SwiftUI

struct InterestCapsuleChip: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let title: String
    var isSelected: Bool
    var isEnabled: Bool = true
    /// 只读展示（如详情「推荐理由」兴趣证据）；不可点。
    var isReadOnly: Bool = false
    let action: () -> Void

    /// 搭子详情等：与兴趣选择页同款胶囊外形，**非选中态**（无 checkmark / prominent）。
    static func readOnlyTag(_ title: String) -> InterestCapsuleChip {
        InterestCapsuleChip(title: title, isSelected: false, isReadOnly: true, action: {})
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isSelected {
                    Label(title, systemImage: "checkmark")
                        .labelStyle(.titleAndIcon)
                } else {
                    Text(title)
                }
            }
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
        }
        .interestCapsuleChrome(isSelected: isSelected, reduceTransparency: reduceTransparency)
        .disabled(!isEnabled)
        .allowsHitTesting(!isReadOnly && isEnabled)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityRemoveTraits(isReadOnly ? .isButton : [])
        .accessibilityLabel(title)
    }
}

extension View {
    @ViewBuilder
    func interestCapsuleChrome(isSelected: Bool, reduceTransparency: Bool) -> some View {
        Group {
            if reduceTransparency {
                if isSelected {
                    self.buttonStyle(.borderedProminent)
                } else {
                    self.buttonStyle(.bordered)
                }
            } else if isSelected {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        }
        .controlSize(.regular)
        .buttonBorderShape(.capsule)
        .tint(isSelected ? Color.accentColor : .primary)
    }
}
