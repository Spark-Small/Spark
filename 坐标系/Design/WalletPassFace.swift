//
//  WalletPassFace.swift
//  坐标系
//
//  App 内 Wallet 风格通行证票面。
//  布局：全幅封面四角 — 左上名称 · 右上日程 · 左下地点 · 右下导航。
//  非 PassKit 渲染；真机票面仍以系统 Wallet 为准。
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

// MARK: - Model

enum WalletPassBarcodeKind: String, Hashable, CaseIterable {
    case qr
    case code128
    case pdf417

    var accessibilityName: String {
        switch self {
        case .qr: "二维码"
        case .code128: "条形码"
        case .pdf417: "二维条码"
        }
    }
}

struct WalletPassFaceContent: Hashable {
    /// 左上：活动名 / 陪玩昵称
    var logoText: String
    var logoSystemImage: String
    /// 标题下方一行（如人数提示）
    var subtitleText: String = ""
    /// 右上上行：星期 + 时刻（Wallet headerFields.label）
    var headerLabel: String = ""
    /// 右上下行：月日；无 label 时单独显示（会员档 / 作品类型等）
    var headerValue: String
    /// 左下字段标签（活动=地点；陪玩=预约）
    var locationLabel: String = "地点"
    /// 左下：地点 / 预约摘要
    var locationText: String = ""
    /// 右下是否显示导航（需 `onNavigate`）
    var showsNavigateButton: Bool = false
    /// 右下是否显示聊天（需 `onMessage`；陪玩长条）
    var showsMessageButton: Bool = false
    /// 右下是否显示详情（需 `onOpenDetail`；在导航左侧）
    var showsDetailButton: Bool = false
    /// 票面中部 Form：活动安排（时间轴摘要）
    var arrangementLines: [String] = []
    /// 票面中部 Form：细则注意事项
    var detailNotes: [String] = []
    var barcodeKind: WalletPassBarcodeKind = .qr
    var barcodeMessage: String = ""
    var stripColor: Color
    var voided: Bool = false

    var hasNotesForm: Bool {
        !arrangementLines.isEmpty || !detailNotes.isEmpty
    }
}

// MARK: - Typography（票面顶栏对齐详情 Form §3.3）

/// App 内票面字阶：顶栏标题/人数/日程跟详情 Form；地点等仍偏 Wallet 密度。
enum WalletPassTypography {
    /// 详情 Form 主文：活动名
    static var logoText: Font { .body }
    /// 详情 Form 副文：参加人数
    static var logoMeta: Font { .subheadline }
    /// 详情 Form 主文：星期 + 时刻
    static var headerLabel: Font { .body }
    /// 详情 Form 副文：月日
    static var headerValue: Font { .subheadline }
    /// secondary / auxiliary label（地点）
    static var fieldLabel: Font { .caption2.weight(.medium) }
    /// secondary / auxiliary value
    static var fieldValue: Font { .footnote.weight(.semibold) }
    /// 中部细则（近 backFields 密度）
    static var notesBody: Font { .footnote }
    static var notesSection: Font { .caption2.weight(.semibold) }
    /// 底栏操作圆钮侧长（与系统导航栏 glass 圆钮同档，供堆高度估算）
    static var actionButtonSide: CGFloat { PlatformMetrics.navigationBarButtonSide }
}

// MARK: - Shared chrome（长条凭证与展开票面共用）

/// 与长条凭证同一套边距，保证展开票面顶栏 / 地点带视觉对齐。
enum WalletPassChromePadding {
    static var horizontal: CGFloat { PlatformMetrics.walletPassChromeInset }
    /// 垂直内边距 = Form 行微调量（由系统列表垂直 margin 推导）
    static var vertical: CGFloat { PlatformMetrics.formRowVerticalPadding }
    static var stackSpacing: CGFloat { PlatformMetrics.sectionSubtitleSpacing }
}

/// 顶栏：左标题/副文 · 右日程（字阶对齐详情 Form：主文 body / 副文 subheadline）
struct WalletPassFaceHeaderRow: View {
    let content: WalletPassFaceContent
    var titleLineLimit: Int = 1

    private var hasSchedule: Bool {
        !content.headerLabel.isEmpty || !content.headerValue.isEmpty
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.cardInfoSpacing) {
            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                Text(content.logoText)
                    .font(WalletPassTypography.logoText)
                    .foregroundStyle(.primary)
                    .lineLimit(titleLineLimit)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !content.subtitleText.isEmpty {
                    Text(content.subtitleText)
                        .font(WalletPassTypography.logoMeta)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(0)

            if hasSchedule {
                VStack(alignment: .trailing, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                    Text(schedulePrimary)
                        .font(WalletPassTypography.headerLabel)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if !scheduleSecondary.isEmpty {
                        Text(scheduleSecondary)
                            .font(WalletPassTypography.headerValue)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(scheduleAccessibilityLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var schedulePrimary: String {
        if !content.headerLabel.isEmpty { return content.headerLabel }
        return content.headerValue
    }

    private var scheduleSecondary: String {
        content.headerLabel.isEmpty ? "" : content.headerValue
    }

    private var scheduleAccessibilityLabel: String {
        [content.headerLabel, content.headerValue]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "，")
    }
}

/// 底栏：地点摘要 + 可选 glass 操作（无标签 / 无按钮时不占位）
struct WalletPassFaceFooterRow: View {
    let content: WalletPassFaceContent
    var onNavigate: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil
    var onOpenDetail: (() -> Void)? = nil
    var locationLineLimit: Int = 1

    private var showsLocationLabel: Bool {
        !content.locationText.isEmpty && !content.locationLabel.isEmpty
    }

    private var showsLocationValue: Bool {
        !content.locationText.isEmpty
    }

    private var trailingSlotCount: Int {
        var count = 0
        if content.showsDetailButton, onOpenDetail != nil { count += 1 }
        if content.showsMessageButton, onMessage != nil { count += 1 }
        if content.showsNavigateButton, onNavigate != nil { count += 1 }
        return count
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.cardInfoSpacing) {
            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                if showsLocationLabel {
                    Text(content.locationLabel)
                        .font(WalletPassTypography.fieldLabel)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if showsLocationValue {
                    Text(content.locationText)
                        .font(showsLocationLabel ? WalletPassTypography.fieldValue : WalletPassTypography.logoMeta)
                        .foregroundStyle(showsLocationLabel ? Color.primary : Color.secondary)
                        .lineLimit(locationLineLimit)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if trailingSlotCount > 0 {
                footerActions
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var footerActions: some View {
        HStack(spacing: PlatformMetrics.sectionSubtitleSpacing) {
            if content.showsDetailButton, let onOpenDetail {
                ActivityDetailControls.GlassIconButton(
                    systemImage: "info.circle",
                    accessibilityLabel: "活动详情",
                    action: onOpenDetail
                )
            }
            if content.showsMessageButton, let onMessage {
                ActivityDetailControls.GlassCapsuleButton(
                    title: "聊天",
                    accessibilityLabel: "联系陪玩",
                    action: onMessage
                )
            }
            if content.showsNavigateButton, let onNavigate {
                ActivityDetailControls.GlassCapsuleButton(
                    title: "导航",
                    accessibilityLabel: ActivityDetailCopy.navigationAction,
                    action: onNavigate
                )
            }
        }
    }
}

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
        .frame(height: PlatformMetrics.walletPassFooterBandHeight)
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
                .background(.ultraThinMaterial, in: Capsule())
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

// MARK: - Strip

struct WalletPassStripMedia: View {
    let photo: CommunityPhotoRef?
    var fallbackSymbol: String
    var fallbackColor: Color = Color(white: 0.2)

    var body: some View {
        let _ = fallbackSymbol
        Group {
            if let photo {
                CommunityRemotePhoto(ref: photo)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
            } else {
                // 无封面：安静色带，不放大符号抢戏
                LinearGradient(
                    colors: [
                        fallbackColor.opacity(0.75),
                        fallbackColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 仅预览 / 无媒体占位仍可用；票面头图默认不再用大符号。
struct WalletPassStripSymbol: View {
    let systemImage: String
    var tint: Color

    var body: some View {
        LinearGradient(
            colors: [tint.opacity(0.75), tint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: systemImage)
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary.opacity(0.35))
                .platformSymbolStyle(.hierarchical)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Barcode（PassKit / 详情仍可用）

struct WalletPassBarcodeView: View {
    let kind: WalletPassBarcodeKind
    let message: String
    /// true：铺满条形区（无左右边距）；false：完整显示（Sheet / 预览）
    var fillsBounds: Bool = false

    var body: some View {
        Group {
            if let image = Self.makeUIImage(kind: kind, message: message) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: fillsBounds ? .fill : .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .clipped()
            } else {
                Image(systemName: kind == .qr ? "qrcode" : "barcode")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .accessibilityLabel("凭证码不可用")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static func makeUIImage(kind: WalletPassBarcodeKind, message: String) -> UIImage? {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Code128 对字符更挑；活动票 message 含冒号时优先走可生成路径
        let preferred = preferredKind(for: kind, message: trimmed)
        if let image = render(kind: preferred, message: trimmed) {
            return image
        }
        if preferred != .pdf417, let image = render(kind: .pdf417, message: trimmed) {
            return image
        }
        if preferred != .qr, let image = render(kind: .qr, message: trimmed) {
            return image
        }
        return nil
    }

    /// Code128 仅 ASCII；含非 ASCII 或易失败字符时改 PDF417。
    private static func preferredKind(
        for kind: WalletPassBarcodeKind,
        message: String
    ) -> WalletPassBarcodeKind {
        guard kind == .code128 else { return kind }
        let ascii = message.unicodeScalars.allSatisfy { $0.isASCII && $0.value < 128 }
        return ascii ? .code128 : .pdf417
    }

    private static func render(kind: WalletPassBarcodeKind, message: String) -> UIImage? {
        let data = Data(message.utf8)
        let context = CIContext()
        let ciImage: CIImage?
        switch kind {
        case .qr:
            let filter = CIFilter.qrCodeGenerator()
            filter.message = data
            filter.correctionLevel = "M"
            ciImage = filter.outputImage
        case .code128:
            let filter = CIFilter.code128BarcodeGenerator()
            filter.message = data
            ciImage = filter.outputImage
        case .pdf417:
            let filter = CIFilter.pdf417BarcodeGenerator()
            filter.message = data
            ciImage = filter.outputImage
        }
        guard let ciImage else { return nil }
        // 拉高条码，铺满横条时更清晰
        let scaleY: CGFloat = kind == .code128 ? 24 : 12
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 12, y: scaleY))
        let white = CIImage(color: .white).cropped(to: scaled.extent)
        let composed = scaled.composited(over: white)
        guard let cg = context.createCGImage(composed, from: composed.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Domain adapters

enum WalletPassPublishedKind: Hashable {
    case post
    case hostedActivity

    var badge: String {
        switch self {
        case .post: "作品"
        case .hostedActivity: "发起"
        }
    }

    var systemImage: String {
        switch self {
        case .post: "text.below.photo"
        case .hostedActivity: "flag.fill"
        }
    }
}

enum WalletPassFaceFactory {
    /// 右上 headerFields：label = 星期+时刻，value = 月日
    static func scheduleFields(from date: Date) -> (label: String, value: String) {
        let label =
            "\(Formatters.weekday.string(from: date)) \(Formatters.shortTime.string(from: date))"
        let value = Formatters.monthDay.string(from: date)
        return (label, value)
    }

    /// 列表长条：一行日程（今天/明天/星期 · 时刻）
    static func listScheduleLine(from date: Date) -> String {
        Formatters.activityEventTime(from: date)
    }

    @MainActor
    static func activity(
        _ activity: Activity,
        barcodeMessage: String? = nil,
        voided: Bool = false
    ) -> WalletPassFaceContent {
        let blueprint = ActivityDetailBlueprint.make(for: activity)
        let schedule = scheduleFields(from: activity.date)
        return WalletPassFaceContent(
            logoText: activity.title,
            logoSystemImage: "ticket",
            subtitleText: attendanceHint(for: activity),
            headerLabel: schedule.label,
            headerValue: schedule.value,
            locationText: activity.location,
            showsNavigateButton: !activity.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            showsDetailButton: true,
            arrangementLines: arrangementLines(from: blueprint.timeline),
            detailNotes: detailNotes(from: blueprint),
            barcodeKind: .code128,
            barcodeMessage: barcodeMessage ?? "coordinate:activity:\(activity.id.uuidString)",
            stripColor: stripColor(for: activity.category),
            voided: voided
        )
    }

    /// 活动票底色：按分类区分，避免长条叠放一片近黑。
    static func stripColor(for category: ActivityCategory) -> Color {
        switch category {
        case .outdoorSports:
            return Color(red: 0.14, green: 0.36, blue: 0.52)
        case .food:
            return Color(red: 0.48, green: 0.28, blue: 0.16)
        case .interestSocial:
            return Color(red: 0.34, green: 0.28, blue: 0.54)
        case .cityExplore:
            return Color(red: 0.16, green: 0.40, blue: 0.42)
        case .handmade:
            return Color(red: 0.46, green: 0.30, blue: 0.38)
        case .learning:
            return Color(red: 0.22, green: 0.36, blue: 0.50)
        case .entertainment:
            return Color(red: 0.44, green: 0.20, blue: 0.34)
        case .all:
            return Color(red: 0.18, green: 0.32, blue: 0.48)
        }
    }

    /// 票面「活动安排」：时间 + 节点标题
    static func arrangementLines(from timeline: [ActivityDetailTimelineItem], limit: Int = 4) -> [String] {
        timeline.prefix(limit).map { item in
            let time = item.time.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if time.isEmpty { return title }
            if title.isEmpty { return time }
            return "\(time) · \(title)"
        }
        .filter { !$0.isEmpty }
    }

    /// 票面「细则注意事项」：准备注意 + 参加须知，去空后截断
    static func detailNotes(from blueprint: ActivityDetailBlueprint, limit: Int = 4) -> [String] {
        var lines: [String] = []
        lines.append(contentsOf: blueprint.prepNotes)
        lines.append(contentsOf: blueprint.registrationNotes)
        return Array(
            lines
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(limit)
        )
    }

    /// 标题下人数提示：只显示已参加人数
    static func attendanceHint(for activity: Activity) -> String {
        "\(activity.joined) 人参加"
    }

    static func booking(
        _ record: BuddyBookingRecord,
        statusOverride: String? = nil,
        barcodeMessage: String? = nil,
        voided: Bool = false
    ) -> WalletPassFaceContent {
        let isVoided = voided || statusOverride == "已作废"
        let schedule = scheduleFields(from: record.scheduledAt)
        let status = statusOverride ?? record.statusLabel
        return WalletPassFaceContent(
            logoText: record.companionNickname,
            logoSystemImage: "person.2.fill",
            subtitleText: status,
            headerLabel: schedule.label,
            headerValue: schedule.value,
            locationLabel: "预约",
            locationText: "\(record.hours) 小时 · \(record.priceText)",
            showsNavigateButton: false,
            showsMessageButton: true,
            showsDetailButton: true,
            barcodeKind: .code128,
            barcodeMessage: barcodeMessage ?? "coordinate:booking:\(record.id.uuidString)",
            stripColor: Color(red: 0.28, green: 0.14, blue: 0.42),
            voided: isVoided
        )
    }

    static func membership(holderName: String, tier: String = "演示会员") -> WalletPassFaceContent {
        WalletPassFaceContent(
            logoText: PassConfiguration.logoText,
            logoSystemImage: "person.text.rectangle",
            headerValue: tier,
            locationText: holderName,
            showsNavigateButton: false,
            barcodeKind: .code128,
            barcodeMessage: "coordinate:membership:\(LocalUserIdentity.current.uuidString)",
            stripColor: Color(red: 0.22, green: 0.28, blue: 0.18)
        )
    }

    static func published(
        kind: WalletPassPublishedKind,
        title: String,
        metaLine: String,
        idHint: String
    ) -> WalletPassFaceContent {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = trimmed.isEmpty ? kind.badge : trimmed
        return WalletPassFaceContent(
            logoText: displayTitle,
            logoSystemImage: kind.systemImage,
            headerValue: kind.badge,
            locationText: metaLine,
            showsNavigateButton: false,
            barcodeKind: .code128,
            barcodeMessage: "coordinate:published:\(kind.badge):\(idHint)",
            stripColor: Color(red: 0.15, green: 0.22, blue: 0.38)
        )
    }

    /// PassRecord → 票面；活动票优先用 when/where 填日程与地点。
    static func fromPassRecord(_ pass: PassRecord) -> WalletPassFaceContent {
        let color: Color = {
            switch pass.style {
            case .eventTicket: return Color(red: 0.18, green: 0.32, blue: 0.48)
            case .coupon: return Color(red: 0.22, green: 0.28, blue: 0.18)
            case .storeCard: return Color(red: 0.28, green: 0.14, blue: 0.42)
            }
        }()

        switch pass.style {
        case .storeCard:
            let tier = pass.secondaryFields.first?.value ?? ""
            let member = pass.primaryFields.first?.value ?? ""
            return WalletPassFaceContent(
                logoText: PassConfiguration.logoText,
                logoSystemImage: pass.style.systemImage,
                headerValue: tier,
                locationText: member,
                showsNavigateButton: false,
                barcodeKind: .code128,
                barcodeMessage: pass.barcodeMessage,
                stripColor: color,
                voided: pass.voided
            )

        case .eventTicket, .coupon:
            let title = pass.primaryFields.first?.value ?? pass.description
            let when = pass.field(key: "when")?.value ?? ""
            let place = pass.field(key: "where")?.value
                ?? pass.field(key: "hours")?.value
                ?? ""
            let hours = pass.field(key: "hours")?.value
            let fee = pass.field(key: "fee")?.value ?? pass.field(key: "price")?.value
            let location: String = {
                if let hours, let fee { return "\(hours) · \(fee)" }
                if !place.isEmpty { return place }
                return fee ?? ""
            }()
            return WalletPassFaceContent(
                logoText: title,
                logoSystemImage: pass.style.systemImage,
                headerValue: when,
                locationText: location,
                showsNavigateButton: pass.field(key: "where") != nil && !(pass.field(key: "where")?.value.isEmpty ?? true),
                barcodeKind: .qr,
                barcodeMessage: pass.barcodeMessage,
                stripColor: color,
                voided: pass.voided
            )
        }
    }

    @MainActor
    static func stripPhoto(
        for pass: PassRecord,
        activities: ActivitiesModel,
        buddies: BuddiesModel
    ) -> CommunityPhotoRef? {
        guard let related = pass.relatedID else { return nil }

        if let activity = activities.activity(id: related) {
            return activity.coverPhoto
        }
        if let order = ActivityPaymentStore.order(id: related),
           let activity = activities.activity(id: order.activityID) {
            return activity.coverPhoto
        }
        if let booking = buddies.bookingRecords.first(where: { $0.id == related }) {
            return buddies.item(for: booking.companionNickname)?.profile.coverPhoto
        }
        return nil
    }
}

/// 通行证详情用：自动挂活动封面或搭子照片。
struct WalletPassRecordFace: View {
    let pass: PassRecord

    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @State private var showNavigationPicker = false
    @State private var showActivityDetail = false

    private var relatedActivity: Activity? {
        guard let related = pass.relatedID else { return nil }
        if let activity = activities.activity(id: related) { return activity }
        if let order = ActivityPaymentStore.order(id: related) {
            return activities.activity(id: order.activityID)
        }
        return nil
    }

    var body: some View {
        let content = enrichedContent
        WalletPassFace(
            content: content,
            photo: WalletPassFaceFactory.stripPhoto(
                for: pass,
                activities: activities,
                buddies: buddies
            ),
            fallbackSymbol: pass.style.systemImage,
            onNavigate: content.showsNavigateButton ? { showNavigationPicker = true } : nil,
            onOpenDetail: content.showsDetailButton && relatedActivity != nil
                ? { showActivityDetail = true }
                : nil
        )
        .navigationDestination(isPresented: $showActivityDetail) {
            if let activity = relatedActivity {
                ActivityDetailView(activityID: activity.id)
            }
        }
        .activityMapNavigationDialog(
            activity: Binding(
                get: { showNavigationPicker ? relatedActivity : nil },
                set: { showNavigationPicker = $0 != nil }
            )
        )
    }

    /// 有关联活动时用实体日程格式覆盖 Pass 文案，保证「日期/星期/时间」一致。
    private var enrichedContent: WalletPassFaceContent {
        var content = WalletPassFaceFactory.fromPassRecord(pass)
        if let activity = relatedActivity {
            let blueprint = ActivityDetailBlueprint.make(for: activity)
            content.logoText = activity.title
            content.subtitleText = WalletPassFaceFactory.attendanceHint(for: activity)
            let schedule = WalletPassFaceFactory.scheduleFields(from: activity.date)
            content.headerLabel = schedule.label
            content.headerValue = schedule.value
            content.locationText = activity.location
            content.showsNavigateButton = !activity.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            content.showsDetailButton = true
            content.arrangementLines = WalletPassFaceFactory.arrangementLines(from: blueprint.timeline)
            content.detailNotes = WalletPassFaceFactory.detailNotes(from: blueprint)
            content.stripColor = WalletPassFaceFactory.stripColor(for: activity.category)
        }
        return content
    }
}

#Preview("Wallet pass faces") {
    ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 16) {
            WalletPassFace(
                content: WalletPassFaceFactory.activity(SampleData.activities[0]),
                photo: SampleData.activities[0].coverPhoto,
                onNavigate: {}
            )
            .frame(width: 220)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
