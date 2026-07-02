// Module: SparkAppShell — Profile tab placeholder for signed-out guests.

import SparkDesignSystem
import SwiftUI

struct GuestProfilePromptView: View {
    let onSignIn: () -> Void

    var body: some View {
        NavigationStack {
            SparkScreenContainer(
                navigationTitle: String(localized: "tab.profile", defaultValue: "我的", comment: "Tab title"),
                titleDisplayMode: .large,
                embedding: .none
            ) {
                ContentUnavailableView {
                    Label(
                        String(
                            localized: "guest.profile.title",
                            defaultValue: "登录后管理账号",
                            comment: "Guest profile title"
                        ),
                        systemImage: "person.crop.circle"
                    )
                } description: {
                    Text(
                        String(
                            localized: "guest.profile.subtitle",
                            defaultValue: "浏览活动和社区无需登录；报名、聊天与发帖需先登录。",
                            comment: "Guest profile subtitle"
                        )
                    )
                } actions: {
                    Button(action: onSignIn) {
                        Text(
                            String(
                                localized: "auth.login.signIn",
                                defaultValue: "登录",
                                comment: "Sign in"
                            )
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
                .sparkContentUnavailableCanvas()
            }
        }
    }
}

#Preview {
    GuestProfilePromptView(onSignIn: {})
}
