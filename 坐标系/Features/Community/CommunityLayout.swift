//
//  CommunityLayout.swift
//  坐标系
//

import SwiftUI
import UIKit

enum CommunityLayout {
    static let mediaAspectRatio: CGFloat = 4 / 5
    static var mediaShape: RoundedRectangle { PlatformMetrics.mediaShape }
}

enum CommunityCopy {
    static let rootTitle = "广场"
}

// MARK: - Feed chrome

extension View {
    func communityFeedChrome() -> some View {
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(PlatformSurface.canvas)
            .contentMargins(
                .horizontal,
                PlatformConversationListRow.horizontalInset,
                for: .scrollContent
            )
            .scrollDismissesKeyboard(.interactively)
    }

    func communityFeedRowChrome() -> some View {
        self
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// 帖子卡片底部 ↔ 下一帖作者行：系统 List 分节间距。
    func communityFeedCardTailSpacing() -> some View {
        padding(.bottom, PlatformConversationListRow.listSectionSpacing)
    }

    func communityDetailScrollChrome() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
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
            }
        }
        .tabViewStyle(.page(indexDisplayMode: pageCount > 1 ? .automatic : .never))
        .aspectRatio(CommunityLayout.mediaAspectRatio, contentMode: .fit)
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
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    fillCropped {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                } else {
                    PlatformPlaceholderFill()
                }
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
