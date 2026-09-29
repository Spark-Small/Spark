//
//  PlatformPhotosPickerChrome.swift
//  坐标系
//
//  PhotosPicker 文案：label 闭包只捕获 Sendable 字符串，预览图放在闭包外。
//

import Foundation

enum PlatformPhotosPickerCopy {
    static func evidenceLabel(
        count: Int,
        emptyTitle: String,
        selectedTitle: (Int) -> String
    ) -> String {
        count == 0 ? emptyTitle : selectedTitle(count)
    }

    static func mediaCountLabel(
        count: Int,
        emptyTitle: String,
        selectedTitle: ((Int) -> String)? = nil
    ) -> String {
        count == 0
            ? emptyTitle
            : (selectedTitle?(count) ?? "已选 \(count) 项，点击更换")
    }
}
