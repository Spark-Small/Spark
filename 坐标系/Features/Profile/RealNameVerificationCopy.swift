//
//  RealNameVerificationCopy.swift
//  坐标系
//

import Foundation

enum RealNameVerificationCopy {
    static let navigationTitle = "实名认证"
    static let documentKindHeader = "证件类型"
    static let documentKindFooter =
        "支持居民身份证或护照。性别与年龄由证件本机识别写入，不可手改；结果为「本机识别」，不表示机关已核验。"
    static let idSectionHeader = "居民身份证"
    static let passportSectionHeader = "护照"
    static let idFooter =
        "拍摄或选取身份证正反面。识别在设备完成，不上传明文证件号；结果为「本机识别」，不表示公安库已核验。"
    static let passportFooter =
        "拍摄或选取护照资料页（含机读码或出生日期更佳）。识别在设备完成，不上传明文护照号；结果为「本机识别」，不表示出入境机关已核验。"
    static let frontTitle = "人像面（正面）"
    static let backTitle = "国徽面（反面）"
    static let passportPageTitle = "资料页"
    static let addFront = "添加正面"
    static let addBack = "添加反面"
    static let addPassportPage = "添加资料页"
    static let changeFront = "更换正面"
    static let changeBack = "更换反面"
    static let changePassportPage = "更换资料页"
    static let submit = "开始识别"
    static let submitting = "正在识别…"
    static let verifiedBadge = "已实名（本机）"
    static let unverifiedBadge = "未实名"
    static let entryTitle = "实名认证"
    static let entryVerified = "已认证"
    static let entryUnverified = "去认证"
    static let lockedHint = "来自实名证件，不可编辑"
    static let needRealNameFirst = "完成实名认证后，性别与年龄将自动生成"
    static let successFeedback = "实名信息已写入基本资料（本机识别）"
    static let maskedLabel = "证件号"
    static let documentKindLabel = "证件"
    static let genderFromID = "性别"
    static let ageFromID = "年龄"
    static let previewHeader = "识别结果预览"
    static func ageValue(_ age: Int) -> String { "\(age) 岁" }
}
