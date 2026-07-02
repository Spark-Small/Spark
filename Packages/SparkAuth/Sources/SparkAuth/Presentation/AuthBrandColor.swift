// Module: SparkAuth — Provider brand tints for login recognition (not decorative chrome).

import SwiftUI

enum AuthBrandColor {
    // REASONING: WeChat / Alipay colors aid channel recognition on CN login screens.
    static let weChat = Color(red: 0.03, green: 0.76, blue: 0.38)
    static let alipay = Color(red: 0.09, green: 0.47, blue: 0.95)

    static func appleSignInBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }

    static func appleSignInForeground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : .white
    }
}
