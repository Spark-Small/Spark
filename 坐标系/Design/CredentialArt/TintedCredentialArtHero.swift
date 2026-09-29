//
//  TintedCredentialArtHero.swift
//  坐标系
//
//  SVGView 渲染 CredentialArt 模板；失败时回退 Assets 矢量图。
//

import SwiftUI
import SVGView

struct TintedCredentialArtHero: View {
    let scene: CredentialArtScene
    let theme: CredentialArtTheme
    var aspectRatio: CGFloat = 375.0 / 120.0

    @State private var svgNode: SVGNode?

    var body: some View {
        ZStack {
            theme.surface

            Group {
                if let svgNode {
                    SVGView(svg: svgNode)
                        .padding(.horizontal, WalletPassChromePadding.horizontal * 1.5)
                        .padding(.vertical, PlatformMetrics.hairlineSpacing * 2)
                } else {
                    Image(scene.fallbackAssetName)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, WalletPassChromePadding.horizontal * 1.5)
                        .padding(.vertical, PlatformMetrics.hairlineSpacing * 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .accessibilityHidden(true)
        }
        .overlay(alignment: .bottom) {
            CredentialArtHeroChrome.fieldSeparator(theme: theme)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
        .task(id: taskKey) {
            await loadSVG()
        }
    }

    private var taskKey: String {
        "\(scene.resourceName)-\(theme.accentHex)-\(theme.accentMutedHex)"
    }

    @MainActor
    private func loadSVG() async {
        guard let data = CredentialArtSVGLoader.tintedData(
            resourceName: scene.resourceName,
            theme: theme
        ),
              let node = SVGParser.parse(data: data) else {
            svgNode = nil
            return
        }
        svgNode = node
    }
}
