// Module: SparkAuth — Localized copy for SignUpView.

import Foundation

enum SignUpCopy {
    static let title = String(
        localized: "auth.signUp.title",
        defaultValue: "注册",
        comment: "Sign up title"
    )
    static let displayNamePlaceholder = String(
        localized: "auth.signUp.displayName",
        defaultValue: "昵称",
        comment: "Display name"
    )
    static let emailPlaceholder = String(
        localized: "auth.login.email",
        defaultValue: "邮箱",
        comment: "Email field"
    )
    static let passwordPlaceholder = String(
        localized: "auth.login.password",
        defaultValue: "密码",
        comment: "Password field"
    )
    static let passwordFooter = String(
        localized: "auth.signUp.footer",
        defaultValue: "密码至少 6 位",
        comment: "Sign up password requirement"
    )
    static let signUpButton = String(
        localized: "auth.signUp.button",
        defaultValue: "创建账号",
        comment: "Sign up button"
    )
}
