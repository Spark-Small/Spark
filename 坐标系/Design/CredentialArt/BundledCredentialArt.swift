//
//  BundledCredentialArt.swift
//  坐标系
//
//  票面 Hero 彩绘入口（SVGView 换色 + Assets 回退）。
//

import SwiftUI

struct CredentialArtHero: View {
    let scene: CredentialArtScene
    let theme: CredentialArtTheme
    var aspectRatio: CGFloat = 375.0 / 120.0

    var body: some View {
        TintedCredentialArtHero(
            scene: scene,
            theme: theme,
            aspectRatio: aspectRatio
        )
    }
}
