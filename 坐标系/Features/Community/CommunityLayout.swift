//
//  CommunityLayout.swift
//  坐标系
//
//  广场内容页几何：一律走 PlatformConversationListRow（subtitleCell 探针）+ 本文件 helper。
//  禁止 Features 再手写 EdgeInsets / 裸 `.padding(.vertical)` / 默认 VStack spacing。
//
//  间距契约：
//  - 水平页边：`contentMargins` ← `horizontalInset`（= PlatformMetrics.contentInset）
//  - 行垂直：`verticalInset` / `PlatformConversationListRow.insets`
//  - 块间距：`rowToContentSpacing`（作者↔媒体等）· `textToSecondarySpacing`（主↔副）
//  - 分节：`listSectionSpacing`
//  - Leading：系统 Dynamic Type 字体行高；不设自定义 `.lineSpacing`
//

import SwiftUI
import UIKit
import CoordinateModels

enum CommunityLayout {
    /// 广场媒体比例：Platform 精选 / 详情头图同族 4:5。
    static var mediaAspectRatio: CGFloat { PlatformMetrics.communityMediaAspectRatio }
    static var mediaShape: RoundedRectangle { PlatformMetrics.mediaShape }
}

// MARK: - Feed / Detail chrome

extension View {
    /// 广场信息流：对齐消息 List chrome（soft 顶边 + 系统水平页边），底面用内容 canvas。
    func communityFeedChrome() -> some View {
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listSectionSpacing(PlatformConversationListRow.listSectionSpacing)
            .environment(\.defaultMinListRowHeight, 0)
            .contentMargins(
                .horizontal,
                PlatformConversationListRow.horizontalInset,
                for: .scrollContent
            )
            .scrollEdgeEffectStyle(.soft, for: .top)
            .scrollDismissesKeyboard(.interactively)
            .background(PlatformSurface.canvas)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: PlatformConversationListRow.listSectionSpacing)
            }
    }

    /// 信息流卡行：水平由 List `contentMargins` 承担。
    func communityFeedRowChrome() -> some View {
        self
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .navigationLinkIndicatorVisibility(.hidden)
    }

    /// 分类 chip 行：与消息分段筛选同行 insets（垂直由 chip bar token 承担）。
    func communityFeedFilterRowChrome() -> some View {
        self
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// 空态块垂直留白。
    func communityEmptyStateChrome() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }

    /// 帖子卡片底部 ↔ 下一帖作者行：系统 List 分节间距。
    func communityFeedCardTailSpacing() -> some View {
        padding(.bottom, PlatformConversationListRow.listSectionSpacing)
    }

    func communityDetailScrollChrome() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .contentMargins(
                .horizontal,
                PlatformConversationListRow.horizontalInset,
                for: .scrollContent
            )
            .background(PlatformSurface.canvas)
    }

    /// 独立内容块（作者行、配图、正文）↔ 下一区块：subtitleCell 行垂直 margin。
    func communityRowToContentSpacing() -> some View {
        padding(.top, PlatformConversationListRow.rowToContentSpacing)
    }

    /// 同一逻辑块内相邻文字/轻控件：subtitleCell 主副文间距。
    func communityInlineSpacing() -> some View {
        padding(.top, PlatformConversationListRow.textToSecondarySpacing)
    }
}

// MARK: - Media

struct CommunityMediaPager<Page: View>: View {
    let pageCount: Int
    @ViewBuilder var page: (_ index: Int) -> Page

    var body: some View {
        TabView {
            ForEach(0..<pageCount, id: \.self) { index in
                page(index)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .clipShape(CommunityLayout.mediaShape)
                    .contentShape(CommunityLayout.mediaShape)
                    .accessibilityLabel(
                        pageCount > 1
                            ? CommunityBrowseCopy.mediaPhotoPage(index: index + 1, total: pageCount)
                            : CommunityBrowseCopy.mediaPhoto
                    )
            }
        }
        .tabViewStyle(.page(indexDisplayMode: pageCount > 1 ? .automatic : .never))
        .aspectRatio(CommunityLayout.mediaAspectRatio, contentMode: .fit)
        .accessibilityElement(children: .contain)
    }
}

struct CommunityRemotePhoto: View {
    var ref: CommunityPhotoRef?

    init(ref: CommunityPhotoRef?) {
        self.ref = ref
    }

    var body: some View {
        Group {
            switch ref {
            case .remote(let url):
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            PlatformPlaceholderFill()
                            ProgressView()
                        }
                    case .success(let image):
                        fillCropped {
                            image
                                .resizable()
                                .scaledToFill()
                        }
                    case .failure:
                        PlatformPlaceholderFill()
                    @unknown default:
                        PlatformPlaceholderFill()
                    }
                }
            case .file(let url):
                LocalFileMediaPhoto(url: url)
            case .asset(let name):
                fillCropped {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                }
            case .seeded(let seed, let symbol):
                SeededSceneFill(seed: seed, symbol: symbol)
            case .none:
                PlatformPlaceholderFill()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func fillCropped<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Color.clear
            .overlay { content() }
            .clipped()
    }
}

/// 本机照片 / 视频：视频取海报帧，并叠播放标识。
private struct LocalFileMediaPhoto: View {
    let url: URL
    @State private var image: UIImage?

    private var isVideo: Bool {
        CommunityPhotoStore.isVideo(url: url)
    }

    var body: some View {
        ZStack {
            if let image {
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                PlatformPlaceholderFill()
            }

            if isVideo, image != nil {
                Image(systemName: "play.circle.fill")
                    .font(PlatformListTypography.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        .task(id: url) {
            if isVideo {
                image = await CommunityPhotoStore.posterImage(for: url)
            } else {
                image = await PlatformLocalImageCache.loadAsync(atPath: url.path)
            }
        }
        .modifier(LocalFileMediaAccessibility(isVideo: isVideo))
    }
}

private struct LocalFileMediaAccessibility: ViewModifier {
    let isVideo: Bool

    func body(content: Content) -> some View {
        if isVideo {
            content.accessibilityLabel(CommunityBrowseCopy.mediaVideo)
        } else {
            content
        }
    }
}
