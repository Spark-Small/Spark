//
//  PlatformTextInputChrome.swift
//  坐标系
//
//  **全 App 文本输入 / 键盘模块入口**（一模块、多 surface 皮）：
//  - `.form` → `platformFormTextInput` / `PlatformReviewsWriteSheet`（发送在导航栏）
//  - `.messageComposer` → `PlatformMessageComposerBar`（字段挂 `platformMessageComposerTextInput`）
//  - `.search` → `.searchable`
//  - `.alert` → Alert `TextField`（可挂 `platformFormTextInput`）
//  - `.credential` → `platformCredentialTextInput`（登录手机号 / 验证码）
//
//  收键盘：`platformTextInputScrollChrome()`；
//  `platformSheet(.form/.browser/.filter/.confirm)` 已自动挂上。
//  messageComposer：**录音态不得 resignFirstResponder / 拆掉 TextField**——键盘应保持，
//  composer 贴在键盘上沿（与系统信息一致）；仅 Form 滚动交互式收键盘。
//  禁止跨 surface 混皮（Form 页套 Messages 胶囊、登录硬塞 Form 行）。
//  CI：`Scripts/check-text-input.sh`（经 `check-imports.sh`）扫裸 TextField 与旁路键盘字典。
//

import SwiftUI

// MARK: - Surface（选用哪套输入皮）

/// 点按输入时的场景家族。同一模块、不同官方推荐皮；Features 只按 surface 选 API。
enum PlatformTextInputSurface: String, CaseIterable, Sendable {
    /// 结构化填写：系统 Form/List `TextField` + `platformFormTextInput`
    case form
    /// 即时消息底栏：`PlatformMessageComposerBar`（录音态保键盘）
    case messageComposer
    /// 导航栏搜索：`.searchable`
    case search
    /// 单字段短创建：Alert 内 `TextField`
    case alert
    /// 登录手机号 / 验证码：`platformCredentialTextInput`
    case credential

    /// 该 surface 应对接的实现名（文档 / 自检用）。
    var implementationName: String {
        switch self {
        case .form: "platformFormTextInput / PlatformReviewsWriteSheet"
        case .messageComposer: "PlatformMessageComposerBar"
        case .search: ".searchable"
        case .alert: "alert TextField + platformFormTextInput"
        case .credential: "platformCredentialTextInput"
        }
    }
}

// MARK: - Credential（登录）

/// 登录凭证字段键盘约定（数字键盘；皮仍是 Login 卡片，不是 Form 行）。
enum PlatformCredentialTextInputKind: Equatable, Sendable {
    /// 手机号
    case phone
    /// 短信验证码
    case oneTimeCode
}

// MARK: - Form 字段角色

/// Form / List 内系统 TextField 的键盘与行限约定（非自定义皮肤）。
enum PlatformFormTextInputKind: Equatable, Sendable {
    /// 单行：标题、地点、标签、城市
    case singleLine
    /// `LabeledContent` 右侧短字段
    case trailing
    /// 右侧标识字段（备注 / @handle）：trailing + 不自动大写
    case trailingIdentifier
    /// `@handle` / UID 等：不自动大写、关闭纠错
    case identifier
    /// 纯数字 UID / 验证码旁路：数字键盘 + identifier 特质
    case digits
    /// Form 右侧纯数字（身高/体重等）：右对齐 + 数字键盘
    case trailingDigits
    /// 邮箱或联系方式
    case contact
    /// 金额：小数键盘 + 右对齐
    case decimalAmount
    /// 右侧估价等：数字与标点（区间 / 「约」）+ 右对齐
    case trailingLooseAmount
    /// 多行正文（简介等）3…8
    case body
    /// 发帖长正文 4…10
    case composeBody
    /// 短留言 / 邀约备注 2…5
    case note
    /// 举报 / 退款 / 反馈说明 4…8
    case report
    /// Form 内发送（评价行）2…6 + Return 键为发送
    case send
    /// 配文等短 caption 2…4
    case caption
}

// MARK: - View API

extension View {
    /// 含文本输入的可滚动页：交互式下滑收起键盘（官方 `scrollDismissesKeyboard`）。
    func platformTextInputScrollChrome() -> some View {
        scrollDismissesKeyboard(.interactively)
    }

    /// Form / List 内 `TextField`：统一 submit、行限与键盘类型；保持系统控件皮。
    func platformFormTextInput(_ kind: PlatformFormTextInputKind) -> some View {
        modifier(PlatformFormTextInputModifier(kind: kind))
    }

    /// Messages 底栏字段：plain + 多行上限 + 发送键；可视皮由 `platformComposerFieldChrome`（glass 胶囊）承担。
    func platformMessageComposerTextInput() -> some View {
        font(.body)
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .submitLabel(.send)
    }

    /// 登录手机号 / 验证码：数字键盘 + 关闭自动更正（卡片皮由 Login 容器承担）。
    func platformCredentialTextInput(_ kind: PlatformCredentialTextInputKind) -> some View {
        modifier(PlatformCredentialTextInputModifier(kind: kind))
    }
}

// MARK: - Modifier

private struct PlatformFormTextInputModifier: ViewModifier {
    let kind: PlatformFormTextInputKind

    @ViewBuilder
    func body(content: Content) -> some View {
        switch kind {
        case .singleLine:
            content
                .submitLabel(.done)
                .textInputAutocapitalization(.sentences)
        case .trailing:
            content
                .multilineTextAlignment(.trailing)
                .submitLabel(.done)
        case .trailingIdentifier:
            content
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
        case .identifier:
            content
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
        case .digits:
            content
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.none)
        case .trailingDigits:
            content
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.none)
                .submitLabel(.done)
        case .contact:
            content
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
        case .decimalAmount:
            content
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        case .trailingLooseAmount:
            content
                .multilineTextAlignment(.trailing)
                .keyboardType(.numbersAndPunctuation)
                .submitLabel(.done)
        case .body:
            content
                .lineLimit(3...8)
        case .composeBody:
            content
                .lineLimit(4...10)
        case .note:
            content
                .lineLimit(2...5)
                .submitLabel(.done)
        case .report:
            content
                .lineLimit(4...8)
        case .send:
            content
                .lineLimit(2...6)
                .submitLabel(.send)
        case .caption:
            content
                .lineLimit(2...4)
                .submitLabel(.done)
        }
    }
}

private struct PlatformCredentialTextInputModifier: ViewModifier {
    let kind: PlatformCredentialTextInputKind

    func body(content: Content) -> some View {
        content
            .font(.body)
            .keyboardType(.numberPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(kind == .phone ? .telephoneNumber : .oneTimeCode)
    }
}
