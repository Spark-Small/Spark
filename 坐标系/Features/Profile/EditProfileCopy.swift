//
//  EditProfileCopy.swift
//  坐标系
//
//  个人资料编辑文案与本机字段限额（对齐 Threads / Settings 编辑气质；未接后端不做唯一性断言）。
//

import CoordinateModels
import Foundation

enum EditProfileCopy {
    static let navigationTitle = "个人资料"
    static let back = "返回"
    static let save = "保存"

    static let addPhoto = "添加照片"
    static let changePhoto = "更改照片"
    static let changePhotoHint = "从照片图库选择头像"
    static let removePhoto = "移除照片"
    static let defaultDisplayName = "坐标系用户"

    static let nameLabel = "昵称"
    static let namePlaceholder = "你的昵称"
    static let handleLabel = "账号"
    static let handlePlaceholder = "username"

    static let aboutHeader = "自我介绍"
    static let bioPlaceholder = "介绍一下自己…"
    static let cityLabel = "常驻城市"
    static let cityPlaceholder = "城市"

    static let demographicsHeader = "基本资料"
    static let genderLabel = "性别"
    static let unset = "未设置"
    static let genderUnset = unset
    static let ageLabel = "年龄"
    static let ageUnset = unset
    /// 性别 / 年龄未写入时的右侧说明（非手填空态）。
    static let certifiedAutoValue = "认证自动生成"
    static let heightLabel = "身高"
    static let heightUnit = "cm"
    static let weightLabel = "体重"
    static let weightUnit = "kg"
    static let availabilityLabel = "档期"
    static let availabilityPlaceholder = "例如：周末白天可约"

    static let occupationLabel = "身份"
    static let meetRadiusLabel = "出行半径"
    static let mbtiLabel = "MBTI"
    static let zodiacLabel = "星座"
    static let zodiacFromBirth = "由生日生成"

    static let promptsHeader = "问答"
    static let promptAdd = "添加问答"
    static let promptRemove = "删除"
    static let promptEditorTitle = "编辑问答"
    static let promptPickHeader = "题目"
    static let promptPickLabel = "选择题目"
    static let promptAnswerHeader = "回答"
    static let promptAnswerPlaceholder = "写一句真实的…"
    static let promptMediaHeader = "配图（可选）"
    static let promptMediaNone = "无图"
    static let promptMediaPick = "选用这张"

    static let interestsHeader = "兴趣"
    static let interestsLabel = "兴趣标签"
    static let interestsEmpty = "未选择"
    static func interestsCount(_ count: Int) -> String { "\(count) 项" }

    static let verificationHeader = "认证与安全"
    static let trustDashboardEntry = "我的信誉"
    static let phoneLabel = "手机号"
    static let phoneUnbound = "未绑定"
    static let phoneBindTitle = "绑定手机号"
    static let phoneBindHeader = "验证手机号"
    static let phoneRebindHeader = "更换手机号"
    static let phoneBindConfirm = "确认绑定"
    static let phoneBindSuccess = "手机号已绑定"
    static let phoneBoundFooter = "已绑定号码仅脱敏展示。更换需重新短信验证。"
    static let phoneBindFooter =
        "验证成功后写入本机会话并点亮「手机已验证」。保留原登录方式。远程专用绑定接口未接前，校验走短信登录契约且不切换 JWT。"
    static let phoneDemoCodeHint = "演示环境：验证码使用 123456。"
    static let photoVerified = "已认证"
    static let photoUnverified = "未认证"
    static let managePhotoVerification = "管理防欺诈认证"
    static let startPhotoVerification = "开始防欺诈认证"
    static let photoVerificationLabel = "防欺诈认证"
    /// 防欺诈认证页说明。
    static let photoVerificationPageFooter =
        "添加认证照并完成摄像头核验。头像不参与比对。性别与年龄由实名认证本机识别写入。"
    static let verificationPhotosHeader = "认证照片"
    static let verificationPhotosEditorFooter =
        "上传 1–2 张本人正脸照，用于摄像头比对。添加后立即生效。关闭「对外展示」后他人看不到，仍用于核验。头像不参与比对。"
    static let verificationPhotoTitlePrefix = "认证照"
    static let verificationPhotoPublic = "对外展示"
    static let verificationPhotoDelete = "删除"
    static let addVerificationPhoto = "添加认证照"
    static let addAnotherVerificationPhoto = "再加一张"
    static let manageVerificationPhotos = "管理认证照"
    static let photosEditorDone = "完成"

    static let uidLabel = "UID"
}

/// 本机编辑限额（Threads 简介约 150；账号长度对齐常见社交客户端）。
enum ProfileEditLimits {
    static let nameMax = 30
    static let handleMax = 24
    static let bioMax = 150
    static let cityMax = 40

    static func clamped(_ text: String, max: Int) -> String {
        String(text.prefix(max))
    }

    /// 去掉前导 `@` 与空白，仅保留字母数字下划线，并截断。
    static func normalizeHandle(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("@") {
            value.removeFirst()
        }
        let allowed = value.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "_"
        }
        return String(String.UnicodeScalarView(allowed).prefix(handleMax))
    }

    static func isHandleFormatOK(_ handle: String) -> Bool {
        handle.isEmpty || handle == normalizeHandle(handle)
    }

    /// 输入过程：仅保留数字并截断位数。
    static func digitsOnly(_ raw: String, maxDigits: Int) -> String {
        let digits = raw.filter(\.isNumber)
        return String(digits.prefix(maxDigits))
    }

    static func parsedHeightCM(_ raw: String) -> Int? {
        parsedMeasurement(
            raw,
            min: ProfileDemographicsLimits.heightMin,
            max: ProfileDemographicsLimits.heightMax
        )
    }

    static func parsedWeightKG(_ raw: String) -> Int? {
        parsedMeasurement(
            raw,
            min: ProfileDemographicsLimits.weightMin,
            max: ProfileDemographicsLimits.weightMax
        )
    }

    private static func parsedMeasurement(_ raw: String, min: Int, max: Int) -> Int? {
        let digits = digitsOnly(raw, maxDigits: 3)
        guard let value = Int(digits), value > 0 else { return nil }
        return Swift.min(Swift.max(value, min), max)
    }
}
