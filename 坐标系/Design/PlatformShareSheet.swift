//
//  PlatformShareSheet.swift
//  坐标系
//
//  系统 UIActivityViewController 的 SwiftUI 桥接；iPhone 从底部呈现。
//

import SwiftUI
import UIKit

struct PlatformShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
