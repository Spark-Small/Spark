//
//  CredentialArtStripRenderer.swift
//  坐标系
//
//  Wallet event strip：与 App 内 CredentialArt 同源 SVG + 主题色。
//  不依赖 CoordinateModels；活动分类 → Scene 的映射在 PassKit / 测试侧。
//

import SVGView
import SwiftUI
import UIKit

@MainActor
enum CredentialArtStripRenderer {
    static func walletStripImage(for scene: CredentialArtScene, pixelSize: CGSize) -> UIImage? {
        let theme = CredentialArtTheme.forScene(scene)
        let canvas = CredentialArtStripCanvas(scene: scene, theme: theme, size: pixelSize)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1
        return renderer.uiImage
    }
}

private struct CredentialArtStripCanvas: View {
    let scene: CredentialArtScene
    let theme: CredentialArtTheme
    let size: CGSize

    var body: some View {
        ZStack {
            theme.surface
            stripArt
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    @ViewBuilder
    private var stripArt: some View {
        if let data = CredentialArtSVGLoader.tintedData(resourceName: scene.resourceName, theme: theme),
           let node = SVGParser.parse(data: data) {
            SVGView(svg: node)
                .padding(.horizontal, size.width * 0.08)
                .padding(.vertical, size.height * 0.06)
        } else {
            Image(scene.fallbackAssetName)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, size.width * 0.08)
                .padding(.vertical, size.height * 0.06)
        }
    }
}
