//
//  HeroMediaCard.swift
//  坐标系
//
//  通用封面叠字卡：活动 / 搭子等发现页共用。
//  常规字阶：封面叠字；无障碍大字号：图下文，避免固定比例裁切。
//

import SwiftUI

enum HeroMediaCardLayout: Equatable {
    /// 发现列表 16:9 卡（活动）
    case discover
    /// 搭子人像竖卡 9:16
    case person

    var aspectRatio: CGFloat {
        switch self {
        case .discover: PlatformMetrics.activityCardAspectRatio
        case .person: PlatformMetrics.personCardAspectRatio
        }
    }

    var shape: RoundedRectangle {
        PlatformMetrics.cardShape
    }

    var titleFont: Font {
        .title3.weight(.bold)
    }

    var timeFont: Font {
        .subheadline.weight(.medium)
    }

    var metaFont: Font {
        .caption
    }

    var stackSpacing: CGFloat { PlatformMetrics.cardInfoSpacing }
}

/// 人物封面：远程 / 本地文件走真实图，种子走人像占位（可多图滑动，对齐广场 `CommunityMediaPager`）
struct HeroPersonCover: View {
    let name: String
    var photos: [CommunityPhotoRef] = []
    var allowsPaging = false

    private var resolvedPhotos: [CommunityPhotoRef] {
        if photos.isEmpty {
            return [.seeded(seed: abs(name.hashValue % 9000) + 100, symbol: "person.fill")]
        }
        return photos
    }

    private var showsPager: Bool {
        allowsPaging && resolvedPhotos.count > 1
    }

    var body: some View {
        Group {
            if showsPager {
                TabView {
                    ForEach(Array(resolvedPhotos.enumerated()), id: \.offset) { index, ref in
                        frame(for: ref)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .accessibilityLabel(
                                "\(name)，第 \(index + 1) 张，共 \(resolvedPhotos.count) 张"
                            )
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .accessibilityElement(children: .contain)
            } else {
                frame(for: resolvedPhotos[0])
                    .accessibilityLabel(name)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func frame(for ref: CommunityPhotoRef) -> some View {
        switch ref {
        case .remote, .file, .asset:
            CommunityRemotePhoto(ref: ref)
        case .seeded(let seed, _):
            SeededPersonFill(seed: seed, name: name)
        }
    }
}

/// 封面卡胶囊操作按钮（报名 / 打招呼 / 邀约）— 发现页统一系统 glass
struct HeroCardCapsuleButton: View {
    enum Kind {
        case bordered
        case prominent
    }

    let title: String
    var kind: Kind = .prominent
    var enabled: Bool = true
    var controlSize: ControlSize = .small
    let action: () -> Void

    var body: some View {
        Group {
            switch kind {
            case .bordered:
                Button(title, action: action)
                    .activitySecondaryCTA(controlSize: controlSize)
            case .prominent:
                Button(title, action: action)
                    .activityPrimaryCTA(controlSize: controlSize)
            }
        }
        .font(.subheadline.weight(.semibold))
        .frame(minWidth: PlatformMetrics.heroActionMinWidth)
        .disabled(!enabled)
    }
}

/// 封面叠字壳：封面 + App Store Today 式 Material 信息栏（文案 / CTA）+ 角标
struct HeroMediaCard<Cover: View, Meta: View, Status: View, Actions: View>: View {
    var layout: HeroMediaCardLayout
    var title: String
    /// false 时由外层负责打开，避免嵌套 Button 打断 zoom
    var enablesOpenTap = true
    var accessibilityLabel: String
    var onOpen: () -> Void
    @ViewBuilder var cover: () -> Cover
    @ViewBuilder var meta: () -> Meta
    @ViewBuilder var status: () -> Status
    @ViewBuilder var actions: () -> Actions

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                stackedBody
            } else {
                overlayBody
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// 无障碍大字号：封面保持比例，文案与 CTA 落在图下，避免叠字裁切
    private var stackedBody: some View {
        VStack(alignment: .leading, spacing: layout.stackSpacing) {
            cover()
                .frame(maxWidth: .infinity)
                .aspectRatio(layout.aspectRatio, contentMode: .fit)
                .clipped()
                .clipShape(layout.shape)
                .contentShape(layout.shape)
                .overlay(alignment: .topLeading) {
                    status()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .modifier(
                    HeroOpenTapModifier(
                        enabled: enablesOpenTap,
                        appliesAccessibility: enablesOpenTap,
                        accessibilityLabel: accessibilityLabel,
                        action: onOpen
                    )
                )

            HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
                VStack(alignment: .leading, spacing: layout.stackSpacing) {
                    Text(title)
                        .font(layout.titleFont)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))

                    meta()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

                actions()
            }
            .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
        }
    }

    private var overlayBody: some View {
        ZStack(alignment: .bottom) {
            cover()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
                VStack(alignment: .leading, spacing: layout.stackSpacing) {
                    Text(title)
                        .font(layout.titleFont)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    meta()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                actions()
            }
            .platformMediaInfoBarChrome(.standard)
        }
        .modifier(
            HeroOpenTapModifier(
                enabled: enablesOpenTap,
                appliesAccessibility: enablesOpenTap,
                accessibilityLabel: accessibilityLabel,
                action: onOpen
            )
        )
        .overlay(alignment: .topLeading) {
            status()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .aspectRatio(layout.aspectRatio, contentMode: .fit)
        .clipShape(layout.shape)
        .contentShape(layout.shape)
    }
}

/// 封面卡次要文案行：叠字与图下文均用系统 `.secondary`（大字号图下不叠 Material）。
struct HeroMediaMetaLine: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let text: String
    var font: Font
    var opacity: Double = 1
    var lineLimit: Int? = 1

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(.secondary.opacity(prefersStacked ? 1 : opacity))
            .lineLimit(
                lineLimit.map {
                    DiscoverAccessibility.bodyLineLimit(for: dynamicTypeSize, regular: $0)
                } ?? DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize)
            )
    }
}

private struct HeroOpenTapModifier: ViewModifier {
    var enabled: Bool
    var appliesAccessibility: Bool
    var accessibilityLabel: String
    var action: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(ActivityCardStatus.openHint)
        } else if appliesAccessibility {
            content
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(ActivityCardStatus.openHint)
        } else {
            content
        }
    }
}
