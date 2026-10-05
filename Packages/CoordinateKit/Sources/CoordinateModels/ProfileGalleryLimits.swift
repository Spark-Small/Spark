//
//  ProfileGalleryLimits.swift
//  CoordinateModels
//
//  个人资料照片墙：本机多图上限（对齐社区发帖媒体条数）。
//

import Foundation

public enum ProfileGalleryLimits {
    public static let maxCount = 9

    public static func clamped(_ names: [String]) -> [String] {
        Array(names.prefix(maxCount))
    }
}
