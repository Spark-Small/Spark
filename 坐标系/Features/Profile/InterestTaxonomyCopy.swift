//
//  InterestTaxonomyCopy.swift
//  坐标系
//
//  选择喜好（编辑资料 / 登录硬门槛）chrome 文案。
//

import Foundation

enum InterestTaxonomyCopy {
    static let navigationTitle = "选择喜好"
    static let freeformSectionTitle = "创建独属于你的爱好"
    static let freeformSectionSymbol = "sparkles"
    static let freeformAddPlaceholder = "例如：汉服、滑板"
    static let addChipTitle = "添加"
    static let addChipAccessibility = "添加爱好"
    static let addChipHint = "添加自定义爱好"
    static let addAlertTitle = "添加爱好"
    static let addAlertConfirm = "添加"
    static let addAlertCancel = "取消"
    static var addAlertMessage: String {
        "最多 \(InterestSelectionLimits.customTagMaxCharacters) 个字"
    }
    static let addFieldFallbackPlaceholder = "爱好"
    static let chipHintSelect = "轻点选择"
    static let chipHintDeselect = "再次轻点可取消"
    static let onboardingContinue = "开启旅程"
    static let onboardingContinueHint = "保存喜好并开启旅程"

    static func categoryAddPlaceholder(categoryTitle: String) -> String {
        "在\(categoryTitle)下添加"
    }
}
