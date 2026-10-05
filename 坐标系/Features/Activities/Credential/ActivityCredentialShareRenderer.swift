//
//  ActivityCredentialShareRenderer.swift
//  坐标系
//
//  纪念票 → UIImage（系统分享 / 保存相册）。
//

import SwiftUI
import UIKit

@MainActor
enum ActivityCredentialShareRenderer {
    private static let cardWidth: CGFloat = 390
    private static let cardHeight: CGFloat = 693

    static func renderMementoCard(
        model: ActivityJourneyCredentialModel,
        shareCaption: String
    ) -> UIImage? {
        let content = ActivityJourneyMementoShareCard(
            model: model,
            shareCaption: shareCaption
        )
        .frame(width: cardWidth, height: cardHeight)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        return renderer.uiImage
    }
}
