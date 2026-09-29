//
//  WalletPassStripViews.swift
//  坐标系
//
//  票面头图：封面图或符号色带占位。
//

import SwiftUI
import CoordinateModels

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
                .font(WalletPassTypography.centerSymbol.weight(.medium))
                .foregroundStyle(.primary.opacity(0.35))
                .platformSymbolStyle(.hierarchical)
        }
        .accessibilityHidden(true)
    }
}
