// Module: SparkAuth — Localized copy for ForgotPasswordView.

import Foundation

enum ForgotPasswordCopy {
    static let title = String(
        localized: "auth.forgotPassword.title",
        defaultValue: "找回密码",
        comment: "Forgot password title"
    )
    static let subtitle = String(
        localized: "auth.forgotPassword.subtitle",
        defaultValue: "验证手机号后即可设置新密码",
        comment: "Forgot password subtitle"
    )
    static let newPasswordPlaceholder = String(
        localized: "auth.forgotPassword.newPassword.placeholder",
        defaultValue: "新密码",
        comment: "New password placeholder"
    )
    static let confirmButton = String(
        localized: "auth.forgotPassword.confirm",
        defaultValue: "确认重置",
        comment: "Confirm password reset"
    )
    static let success = String(
        localized: "auth.forgotPassword.success",
        defaultValue: "密码已重置，正在进入应用…",
        comment: "Password reset success"
    )
    static let newPasswordFooter = String(
        localized: "auth.forgotPassword.newPassword.footer",
        defaultValue: "密码至少 6 位",
        comment: "New password requirement"
    )
}
