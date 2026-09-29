//
//  WalletPassBarcodeView.swift
//  坐标系
//
//  票面条码 / 二维码（CoreImage）；PassKit / 详情仍可复用。
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

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
