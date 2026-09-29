//
//  WalletPassFaceContent.swift
//  坐标系
//
//  App 内 Wallet 风格通行证：票面内容模型与条码种类。
//

import SwiftUI

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
