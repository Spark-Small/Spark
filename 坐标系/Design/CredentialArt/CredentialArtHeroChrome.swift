//
//  CredentialArtHeroChrome.swift
//  坐标系
//
//  CredentialArt 头图与票面 / Glass 卡片的衔接层。
//

import SwiftUI

enum CredentialArtHeroChrome {
    static func fieldSeparator(theme _: CredentialArtTheme) -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.06))
            .frame(height: 1)
    }
}
