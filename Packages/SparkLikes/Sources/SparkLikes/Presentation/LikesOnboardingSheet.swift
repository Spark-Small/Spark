// Module: SparkLikes — One-screen discover primer (first visit).

import SwiftUI

struct LikesOnboardingSheet: View {
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(
                        String(
                            localized: "likes.onboarding.swipe",
                            defaultValue: "上下滑浏览推荐",
                            comment: "Onboarding swipe"
                        ),
                        systemImage: "arrow.up.arrow.down"
                    )
                    Label(
                        String(
                            localized: "likes.onboarding.inbound",
                            defaultValue: "点顶栏 ♥ 查看谁喜欢你",
                            comment: "Onboarding inbound"
                        ),
                        systemImage: "heart.text.square"
                    )
                    Label(
                        String(
                            localized: "likes.onboarding.match",
                            defaultValue: "互相喜欢后可发消息",
                            comment: "Onboarding match"
                        ),
                        systemImage: "bubble.left.and.bubble.right"
                    )
                }
            }
            .navigationTitle(
                String(localized: "likes.onboarding.title", defaultValue: "发现朋友", comment: "Onboarding title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.continue", defaultValue: "开始", comment: "Continue")) {
                        onContinue()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LikesOnboardingSheet(onContinue: {})
}
