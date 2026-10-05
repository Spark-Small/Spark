//
//  PlatformProfileChrome.swift
//  坐标系
//
//  「我的」间距契约（对齐 Settings / Project/05）：
//  - 二级 List/Form：insetGrouped + 系统分组页边；默认非 compact
//  - 货架库页：发现同源 discoverBrowse*（contentInset / cardSpacing / soft 顶边）
//  - 全宽卡行：水平 inset = 0，垂直用系统 list margin
//  - 账户头行：仿 Settings Apple ID（约定头像边长 + subtitleCell 间距探针）
//

import SwiftUI

/// Settings「Apple ID」账户行几何：头像无公开 token，业界常用 60pt；间距跟 subtitleCell。
enum PlatformAccountHeaderMetrics {
    static let avatarSide: CGFloat = 60
    static var imageToTextPadding: CGFloat { PlatformConversationListRow.imageToTextPadding }
    static var textToSecondarySpacing: CGFloat { PlatformConversationListRow.textToSecondarySpacing }
    /// 单 cell 内：账户头 ↔ 下方内容块（四列等）= subtitleCell 行垂直 margin（非整行叠两份 inset）。
    static var headerToFooterSpacing: CGFloat { PlatformConversationListRow.rowToContentSpacing }
}

/// `NavigationLink` label：大圆头像 + 名（可选认证勾 / VIP）/ 副文（系统 disclosure 由外层 Link 提供）。
struct PlatformAccountHeaderLabel<Avatar: View>: View {
    let title: String
    var subtitle: String? = nil
    /// 形象认证通过：名后多色 `checkmark.seal.fill`（不用红名）。
    var showsPhotoVerified = false
    /// 会员已开通：名后 VIP 字标。
    var showsMemberVIP = false
    @ViewBuilder var avatar: () -> Avatar

    private var trimmedSubtitle: String? {
        guard let subtitle else { return nil }
        let trimmed = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformAccountHeaderMetrics.imageToTextPadding) {
            avatar()
                .frame(
                    width: PlatformAccountHeaderMetrics.avatarSide,
                    height: PlatformAccountHeaderMetrics.avatarSide
                )

            VStack(alignment: .leading, spacing: PlatformAccountHeaderMetrics.textToSecondarySpacing) {
                HStack(spacing: PlatformMetrics.detailMicroSpacing) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .layoutPriority(1)

                    if showsPhotoVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .symbolRenderingMode(.multicolor)
                            .imageScale(.small)
                            .accessibilityLabel("已认证")
                    }

                    if showsMemberVIP {
                        Text("VIP")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .accessibilityLabel("会员")
                    }
                }

                if let trimmedSubtitle {
                    Text(trimmedSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension View {
    /// 「我的」二级页（设置 / 钱包 / 社交图等）：Settings 同族。
    /// - Parameter flushTop: 首卡顶贴导航栏（钱包卡面、会员 Form）
    /// - Parameter compactSections: 仅密 Form（凭证履约）使用；默认 false
    func profileSecondaryListChrome(
        flushTop: Bool = false,
        compactSections: Bool = false,
        softTopEdge: Bool = true
    ) -> some View {
        modifier(
            ProfileSecondaryListChromeModifier(
                flushTop: flushTop,
                compactSections: compactSections,
                softTopEdge: softTopEdge
            )
        )
    }

    /// 「我的」内容库货架（活动横卡 / 陪玩网格 / 俱乐部海报）：与发现同 gutter / 顶底页边 / soft 顶边。
    func profileLibraryBrowseChrome(softTopEdge: Bool = true) -> some View {
        discoverBrowseScrollChrome(softTopEdge: softTopEdge)
    }

    /// insetGrouped 内全宽数字卡 / 票面：水平 0（系统分组页边）；垂直 subtitleCell margin。
    func profileGroupedFullBleedRowChrome() -> some View {
        listRowInsets(
            EdgeInsets(
                top: 0,
                leading: 0,
                bottom: PlatformConversationListRow.verticalInset,
                trailing: 0
            )
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

private struct ProfileSecondaryListChromeModifier: ViewModifier {
    let flushTop: Bool
    let compactSections: Bool
    let softTopEdge: Bool

    func body(content: Content) -> some View {
        Group {
            if compactSections {
                content
                    .listStyle(.insetGrouped)
                    .listSectionSpacing(.compact)
            } else {
                content
                    .listStyle(.insetGrouped)
            }
        }
        .modifier(ProfileSecondaryFlushTopModifier(enabled: flushTop))
        .modifier(ProfileSecondarySoftTopEdgeModifier(enabled: softTopEdge))
    }
}

private struct ProfileSecondaryFlushTopModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.contentMargins(.top, 0, for: .scrollContent)
        } else {
            content
        }
    }
}

private struct ProfileSecondarySoftTopEdgeModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
    }
}
