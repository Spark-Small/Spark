//
//  DetailHeroChrome.swift
//  坐标系
//
//  详情头图 + 左下信息胶囊：系统 controlSize / glass / platformMediaChromeInset，活动与搭子共用。
//

import SwiftUI

/// 详情头图容器：3:4 圆角卡 + 左下信息胶囊（大字号时落至图下）。
struct DetailHeroChrome<Gallery: View, Chip: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var showsChip: Bool = true
    @ViewBuilder var gallery: () -> Gallery
    @ViewBuilder var chip: (_ onMedia: Bool) -> Chip

    var body: some View {
        let prefersStacked = DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
        let framed = gallery()
            .frame(maxWidth: .infinity)
            .aspectRatio(PlatformMetrics.detailHeroAspectRatio, contentMode: .fit)

        let chipView = chip(!prefersStacked)

        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
                    framed
                    if showsChip {
                        chipView
                            .padding(.horizontal, PlatformMetrics.contentInset)
                    }
                }
            } else {
                framed.overlay(alignment: .bottomLeading) {
                    if showsChip {
                        chipView.platformMediaChromeInset()
                    }
                }
            }
        }
    }
}

/// 头图左下 glass 信息胶囊（系统 `.regular` glass，尺寸与内边距由 controlSize 决定）。
struct DetailHeroInfoChip: View {
    let title: String
    let systemImage: String
    var onMedia: Bool

    var body: some View {
        Button {} label: {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .symbolRenderingMode(.hierarchical)
        }
        .activityGlassCapsule(controlSize: .regular)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityLabel(title)
    }
}
