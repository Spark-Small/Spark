//
//  ProfileLegalConsentViews.swift
//  坐标系
//
//  协议同意门闸（产品 Tip 见 ProfileProductTipsViews）。
//

import CoordinateModels
import SwiftUI
import UIKit
import UserNotifications

private enum LegalConsentDocument: String, Identifiable {
    case agreement
    case privacy

    var id: String { rawValue }

    var hosted: LegalHostedDocument {
        switch self {
        case .agreement: .agreement
        case .privacy: .privacy
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .agreement: UserAgreementView()
        case .privacy: PrivacyPolicyView()
        }
    }
}

private enum LegalConsentCopy {
    static var checkboxLabel: AttributedString {
        linked(
            "同意《用户协议》和《隐私政策》",
            agreement: "《用户协议》",
            privacy: "《隐私政策》"
        )
    }

    static let alertMessage = """
    感谢你选择坐标系！我们非常重视你的个人信息和隐私保护：

    1. 我们将遵循合法、正当、必要和诚信原则收集、使用信息。例如为完成账号登录与安全保障，可能收集手机号码等。

    2. 基于你的授权，我们可能申请位置、相机、相册、日历与通知等权限；默认不开启。相机与认证照用于形象核验与内容安全，你可拒绝或在系统设置中关闭，拒绝不影响浏览基本内容。

    请阅读《用户协议》与《隐私政策》。点击「同意」即表示你已阅读并同意上述内容。
    """

    private static func linked(
        _ raw: String,
        agreement: String,
        privacy: String
    ) -> AttributedString {
        var text = AttributedString(raw)
        if let range = text.range(of: agreement) {
            text[range].foregroundColor = .accentColor
            text[range].link = URL(string: "legal://agreement")
        }
        if let range = text.range(of: privacy) {
            text[range].foregroundColor = .accentColor
            text[range].link = URL(string: "legal://privacy")
        }
        return text
    }

    /// 优先打开托管 HTTPS 页；无法打开时回退 App 内长文。
    @MainActor
    static func open(_ url: URL, into document: Binding<LegalConsentDocument?>) -> OpenURLAction.Result {
        let sheetDocument: LegalConsentDocument
        switch url.absoluteString {
        case "legal://agreement":
            sheetDocument = .agreement
        case "legal://privacy":
            sheetDocument = .privacy
        default:
            return .systemAction
        }
        let target = sheetDocument.hosted.hostedURL
        if UIApplication.shared.canOpenURL(target) {
            UIApplication.shared.open(target)
            return .handled
        }
        document.wrappedValue = sheetDocument
        return .handled
    }
}

private extension View {
    func legalDocumentSheet(_ document: Binding<LegalConsentDocument?>) -> some View {
        sheet(item: document) { doc in
            NavigationStack {
                doc.destination
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .platformSheetConfirmationToolbar("完成") {
                        document.wrappedValue = nil
                    }
            }
            .platformSheet(.browser)
        }
    }
}

extension View {
    /// 合规确认：系统 `.alert`（同意 / 拒绝）；完整协议经勾选行链接查看。
    func legalConsentAlert(
        isPresented: Binding<Bool>,
        onAgree: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) -> some View {
        alert("用户协议与隐私保护", isPresented: isPresented) {
            Button("同意") {
                LegalConsentPreference.accept()
                onAgree()
            }
            Button("拒绝", role: .cancel) {
                onReject()
            }
        } message: {
            Text(LegalConsentCopy.alertMessage)
        }
    }
}

/// 登录 / 创建账号：系统 `Toggle` 同意协议；打开时先出协议弹窗。
struct LegalConsentCheckbox: View {
    @Binding var isChecked: Bool
    @Binding var showAlert: Bool
    var centersContent = true

    @State private var document: LegalConsentDocument?

    private var consentBinding: Binding<Bool> {
        Binding(
            get: { isChecked },
            set: { newValue in
                if newValue {
                    if !isChecked {
                        showAlert = true
                    }
                } else {
                    isChecked = false
                }
            }
        )
    }

    var body: some View {
        Toggle(isOn: consentBinding) {
            Text(LegalConsentCopy.checkboxLabel)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(centersContent ? .center : .leading)
                .environment(\.openURL, OpenURLAction { url in
                    LegalConsentCopy.open(url, into: $document)
                })
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: centersContent ? .center : .leading)
        }
        .accessibilityLabel(isChecked ? "已同意用户协议和隐私政策" : "同意用户协议和隐私政策")
        .accessibilityValue(isChecked ? "已开启" : "已关闭")
        .accessibilityHint(isChecked ? "再次点击可取消同意" : "打开用户协议与隐私保护说明")
        .legalDocumentSheet($document)
    }
}

/// 已登录用户遇协议版本升级：系统 Alert 确认，拒绝可退出。
struct LegalConsentGate: View {
    var onAccepted: () -> Void

    @State private var showAlert = true
    @State private var confirmExit = false

    var body: some View {
        LaunchStageBackground()
            .legalConsentAlert(
                isPresented: $showAlert,
                onAgree: onAccepted,
                onReject: { confirmExit = true }
            )
            .alert("确认退出？", isPresented: $confirmExit) {
                Button("再想想", role: .cancel) {
                    showAlert = true
                }
                Button("退出应用", role: .destructive) {
                    exit(0)
                }
            } message: {
                Text("拒绝将无法使用坐标系。你可以稍后再打开应用并重新阅读协议。")
            }
    }
}

