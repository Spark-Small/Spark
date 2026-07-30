//
//  PlatformFilterChip.swift
//  坐标系
//
//  横向筛选 chip：系统 Label 间距 + 材质胶囊（Photos / App Store 筛选语义）。
//  故意不用 .glass / GlassEffectContainer —— 避免初始化失败导致白屏；
//  规格对齐 `.controlSize(.regular)` + capsule，与主 CTA glass 家族分离。
//

import SwiftUI

struct PlatformFilterChipButton: View {
    let title: String
    let systemImage: String
    var isSelected = false
    var symbolColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbolColor {
                    Image(systemName: systemImage)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(symbolColor, symbolColor.opacity(0.55))
                } else {
                    Image(systemName: systemImage)
                }

                Text(title)
            }
        }
        .platformMaterialChipStyle(isSelected: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PlatformFilterChipMenu<Content: View>: View {
    let title: String
    let systemImage: String
    var isSelected = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        Menu(content: content) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
        }
        .platformMaterialChipStyle(isSelected: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PlatformFilterChipBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                content
            }
            .padding(.horizontal, PlatformMetrics.contentInset)
        }
        .scrollContentBackground(.hidden)
        .labelStyle(.titleAndIcon)
    }
}

#Preview("Filter Chips") {
    ZStack {
        PlatformSurface.groupedPage.ignoresSafeArea()
        PlatformFilterChipBar {
            PlatformFilterChipButton(
                title: "筛选",
                systemImage: "line.3.horizontal.decrease",
                action: {}
            )
            PlatformFilterChipButton(
                title: "全部",
                systemImage: "square.grid.2x2",
                isSelected: true,
                action: {}
            )
            PlatformFilterChipButton(
                title: "运动",
                systemImage: "figure.hiking",
                action: {}
            )
            PlatformFilterChipMenu(
                title: "爱好",
                systemImage: "heart",
                isSelected: false
            ) {
                Button("不限") {}
            }
        }
    }
}
