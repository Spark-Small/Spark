//
//  WalletPassFace.swift
//  坐标系
//
//  App 内 Wallet 风格通行证票面编排（头图 · 细则 · 条码 · 底栏）。
//  非 PassKit 渲染；真机票面仍以系统 Wallet 为准。
//

import SwiftUI
import CoordinateModels

// MARK: - Face

/// App 内票面：履约向布局 — 头图认票 · 地点导航；安排/细则/顶栏字段可由页面 Form 承接。
struct WalletPassFace<Strip: View>: View {
    let content: WalletPassFaceContent
    /// false：安排/细则不画在票面上（由展开页 Form 承接）
    var embedsNotes: Bool = true
    /// false：标题/人数/日程不叠在头图上（由展开页 List 承接）
    var embedsHeader: Bool = true
    var onNavigate: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil
    var onOpenDetail: (() -> Void)? = nil
    @ViewBuilder var strip: () -> Strip

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

    private var showsNotesOnFace: Bool {
        embedsNotes && content.hasNotesForm
    }

    var body: some View {
        Color.clear
            .aspectRatio(PlatformMetrics.walletPassFaceAspectRatio, contentMode: .fit)
            .overlay {
                faceStack
            }
            .clipShape(PlatformMetrics.walletPassFaceShape)
            .contentShape(PlatformMetrics.walletPassFaceShape)
            .overlay {
                PlatformMetrics.walletPassFaceShape
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
            .overlay { voidedOverlay }
            .colorScheme(.dark)
            .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var faceStack: some View {
        // GeometryReader 先分给条码/地点固定带高，剩余给头图，避免底栏被裁出票面
        GeometryReader { geo in
            VStack(spacing: 0) {
                stripHeader
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)

                if showsNotesOnFace {
                    notesPanel
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height * 0.28)
                }

                if showsBarcodeStrip {
                    barcodeBand
                        .layoutPriority(1)
                }

                footerBand
                    .layoutPriority(1)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    private var showsBarcodeStrip: Bool {
        !content.barcodeMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 长条码优先线性码，便于横条扫描。
    private var stripBarcodeKind: WalletPassBarcodeKind {
        switch content.barcodeKind {
        case .code128, .pdf417: content.barcodeKind
        case .qr: .code128
        }
    }

    /// 插画区；可选叠顶栏（长条 / 默认票面）
    private var stripHeader: some View {
        ZStack(alignment: .topLeading) {
            strip()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                stops: embedsHeader
                    ? [
                        .init(color: .black.opacity(0.58), location: 0),
                        .init(color: .black.opacity(0.28), location: 0.45),
                        .init(color: .black.opacity(0.12), location: 1)
                    ]
                    : [
                        .init(color: .black.opacity(0.12), location: 0),
                        .init(color: .black.opacity(0.08), location: 1)
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            if embedsHeader {
                WalletPassFaceHeaderRow(content: content)
                    .padding(.horizontal, WalletPassChromePadding.horizontal)
                    .padding(.top, WalletPassChromePadding.vertical)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 中部：同色扁平分区（非 Form，避免 inset 黑块）
    private var notesPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                if !content.arrangementLines.isEmpty {
                    notesSection(
                        title: "活动安排",
                        lines: Array(content.arrangementLines.prefix(4))
                    )
                }
                if !content.detailNotes.isEmpty {
                    notesSection(
                        title: "细则注意事项",
                        lines: Array(content.detailNotes.prefix(4))
                    )
                }
            }
            .padding(.horizontal, WalletPassChromePadding.horizontal)
            .padding(.vertical, PlatformMetrics.cardInfoSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(content.stripColor)
    }

    private func notesSection(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(WalletPassTypography.notesSection)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    if index > 0 {
                        Divider()
                            .overlay(Color.white.opacity(0.12))
                    }
                    Text(line)
                        .font(WalletPassTypography.notesBody)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(lines.joined(separator: "，"))")
    }

    /// 地点上方：长条凭证码（铺满条形区，无左右边距）
    private var barcodeBand: some View {
        WalletPassBarcodeView(
            kind: stripBarcodeKind,
            message: content.barcodeMessage,
            fillsBounds: true
        )
        .frame(maxWidth: .infinity)
        .frame(height: PlatformMetrics.walletPassFooterBandHeight(
            navigationBarButtonSide: chromeMeasurements.navigationBarButtonSide
        ))
        .clipped()
        .accessibilityLabel("凭证码")
        .accessibilityValue(content.barcodeMessage)
    }

    /// 左下地点 · 右下详情 + 聊天/导航（与长条凭证同一套 footer + 边距）
    private var footerBand: some View {
        WalletPassFaceFooterRow(
            content: content,
            onNavigate: onNavigate,
            onMessage: onMessage,
            onOpenDetail: onOpenDetail
        )
        .padding(.horizontal, WalletPassChromePadding.horizontal)
        .padding(.vertical, WalletPassChromePadding.vertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(content.stripColor)
    }

    @ViewBuilder
    private var voidedOverlay: some View {
        if content.voided {
            Color.black.opacity(0.45)
            Text("已作废")
                .font(WalletPassTypography.headerValue)
                .foregroundStyle(.primary)
                .padding(.horizontal, WalletPassChromePadding.horizontal)
                .padding(.vertical, PlatformMetrics.cardInfoSpacing)
                .platformUltraThinMaterialBackground(in: Capsule())
        }
    }
}

extension WalletPassFace where Strip == WalletPassStripMedia {
    init(
        content: WalletPassFaceContent,
        photo: CommunityPhotoRef?,
        fallbackSymbol: String? = nil,
        embedsNotes: Bool = true,
        embedsHeader: Bool = true,
        onNavigate: (() -> Void)? = nil,
        onMessage: (() -> Void)? = nil,
        onOpenDetail: (() -> Void)? = nil
    ) {
        self.content = content
        self.embedsNotes = embedsNotes
        self.embedsHeader = embedsHeader
        self.onNavigate = onNavigate
        self.onMessage = onMessage
        self.onOpenDetail = onOpenDetail
        let symbol = fallbackSymbol ?? content.logoSystemImage
        self.strip = {
            WalletPassStripMedia(
                photo: photo,
                fallbackSymbol: symbol,
                fallbackColor: content.stripColor
            )
        }
    }
}

extension WalletPassFace where Strip == WalletPassStripSymbol {
    init(
        content: WalletPassFaceContent,
        symbol: String,
        embedsNotes: Bool = true,
        embedsHeader: Bool = true,
        onNavigate: (() -> Void)? = nil,
        onMessage: (() -> Void)? = nil,
        onOpenDetail: (() -> Void)? = nil
    ) {
        self.content = content
        self.embedsNotes = embedsNotes
        self.embedsHeader = embedsHeader
        self.onNavigate = onNavigate
        self.onMessage = onMessage
        self.onOpenDetail = onOpenDetail
        self.strip = { WalletPassStripSymbol(systemImage: symbol, tint: content.stripColor) }
    }
}
