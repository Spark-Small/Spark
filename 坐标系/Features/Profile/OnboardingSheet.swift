//
//  OnboardingSheet.swift
//  坐标系
//

import SwiftUI

/// 登录后的兴趣选择引导：只问「喜欢什么」，降低完善资料门槛。
struct OnboardingSheet: View {
    var onComplete: (_ interests: [String]) -> Void

    @State private var selectedInterests: Set<String> = []
    @State private var appeared = false

    private var canContinue: Bool {
        InterestSelectionLimits.meetsMinimum(selectedInterests.count)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("你对什么感兴趣？")
                            .font(.title.bold())
                        Text("选 \(InterestSelectionLimits.minimum)–\(InterestSelectionLimits.maximum) 项即可。没有的点分类后的「自定义」，或加在最后的自定义分类。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    InterestTaxonomyPicker(
                        selected: $selectedInterests,
                        sectionSpacing: 22
                    )

                    VStack(spacing: 10) {
                        Text(InterestSelectionLimits.progressText(count: selectedInterests.count))
                            .font(.caption)
                            .foregroundStyle(canContinue ? Color.secondary : Color.red)
                            .frame(maxWidth: .infinity)
                            .animation(.easeOut(duration: 0.2), value: selectedInterests.count)

                        PrimaryButton(
                            title: "开启你的活动旅程",
                            isEnabled: canContinue
                        ) {
                            onComplete(Array(selectedInterests))
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
}

#Preview {
    OnboardingSheet { _ in }
}
