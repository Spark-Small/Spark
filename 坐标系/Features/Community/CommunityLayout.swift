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

    /// 顶栏下方频道横滑轨：行向两侧撑满 List，水平边距由 `DiscoverHorizontalRail` 的
    /// `contentMargins` 提供（与活动发现页货架一致，避免与 List 页边叠加）。
    func communityFeedChannelRowChrome() -> some View {
        let horizontal = PlatformConversationListRow.horizontalInset
        return listRowInsets(
            EdgeInsets(
                top: PlatformConversationListRow.verticalInset,
                leading: -horizontal,
                bottom: PlatformConversationListRow.listSectionSpacing,
                trailing: -horizontal
            )
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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

/// 社区评论输入：快捷表情 + 头像胶囊栏（对齐主流社交评论 Sheet）。
struct CommunityCommentComposer: View {
    @Binding var draft: String
    var placeholder: String = "我来说两句..."
    var authorName: String
    var isFocused: FocusState<Bool>.Binding
    var replyPreview: (sender: String, text: String)? = nil
    var onCancelReply: (() -> Void)? = nil
    var onGIF: (() -> Void)? = nil
    var onSend: () -> Void

    private let quickEmojis = ["❤️", "🙌", "🔥", "👏", "😢", "😍", "😮", "😂"]

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
            if let replyPreview {
                HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                    Text("回复 \(replyPreview.sender)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(replyPreview.text)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let onCancelReply {
                        Button("取消", action: onCancelReply)
                            .font(.caption)
                            .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, PlatformConversationListRow.horizontalInset)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(quickEmojis, id: \.self) { emoji in
                        Button {
                            draft.append(emoji)
                            isFocused.wrappedValue = true
                        } label: {
                            Text(emoji)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, PlatformConversationListRow.horizontalInset)
            }

            HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                PlatformListAvatarView(
                    name: authorName,
                    side: PlatformConversationListRow.imageSide * 0.72
                )

                HStack(spacing: 8) {
                    TextField(placeholder, text: $draft, axis: .vertical)
                        .font(.body)
                        .focused(isFocused)
                        .lineLimit(1...4)

                    if canSend {
                        Button(action: onSend) {
                            Image(systemName: "paperplane.fill")
                                .font(.body)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("发送")
                    } else if let onGIF {
                        Button("GIF", action: onGIF)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .accessibilityLabel("GIF")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemFill), in: Capsule())
            }
            .padding(.horizontal, PlatformConversationListRow.horizontalInset)
            .padding(.bottom, PlatformConversationListRow.verticalInset)
        }
        .padding(.top, PlatformConversationListRow.textToSecondarySpacing)
        .background(.bar)
    }
}

enum CommunityCommentAccessory {
    case gif

    var accessibilityLabel: String {
        switch self {
        case .gif: "GIF"
        }
    }
}
