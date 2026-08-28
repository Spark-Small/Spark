//
//  AppWelcomeGuideView.swift
//  坐标系
//
//  半屏分页 onboarding：SVG 插画 + 价值文案。
//  Sheet 用系统 `.medium`（PlatformSheet.confirm）。
//

import SwiftUI

enum AppWelcomeGuideCopy {
    static let storageKey = "app.hasSeenWelcomeGuide"
    static let skip = "跳过"
    static let next = "继续"
    static let start = "立即出发"
}

private enum AppWelcomeModule: String, CaseIterable, Identifiable {
    case welcome
    case activities
    case buddies
    case community

    var id: String { rawValue }

    var title: String {
        switch self {
        case .welcome: "欢迎来到坐标系"
        case .activities: "发现好玩的活动"
        case .buddies: "找到有趣的人"
        case .community: "看看大家怎么玩"
        }
    }

    var message: String {
        switch self {
        case .welcome: "让一起玩，变得简单、自然、可信。"
        case .activities: "按兴趣浏览各类活动，喜欢就直接报名参加。"
        case .buddies: "按兴趣和时间匹配，更快约到合适的搭子和陪玩。"
        case .community: "在广场里畅所欲言，发表你的高光时刻和你的奇思妙想。"
        }
    }

    var illustrationName: String {
        switch self {
        case .welcome: "WelcomeGuideWelcome"
        case .activities: "WelcomeGuideActivities"
        case .buddies: "WelcomeGuideBuddies"
        case .community: "WelcomeGuideCommunity"
        }
    }
}

struct AppWelcomeGuideView: View {
    var onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var pageID = AppWelcomeModule.welcome.id

    private var modules: [AppWelcomeModule] { AppWelcomeModule.allCases }

    private var isLastPage: Bool {
        pageID == modules.last?.id
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $pageID) {
                ForEach(modules) { module in
                    pageContent(module)
                        .tag(module.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : .easeInOut, value: pageID)
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppWelcomeGuideCopy.skip, action: finish)
                }
            }
            .sensoryFeedback(.selection, trigger: pageID)
        }
        .tint(PlatformAction.brandAccent)
        .platformSheet(.confirm, interactiveDismissDisabled: true)
    }

    private func pageContent(_ module: AppWelcomeModule) -> some View {
        VStack {
            Image(module.illustrationName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .accessibilityHidden(true)

            VStack {
                Text(module.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(module.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
    }

    private var bottomBar: some View {
        Button {
            if isLastPage {
                finish()
            } else if let index = modules.firstIndex(where: { $0.id == pageID }),
                      modules.indices.contains(index + 1) {
                pageID = modules[index + 1].id
            }
        } label: {
            Text(isLastPage ? AppWelcomeGuideCopy.start : AppWelcomeGuideCopy.next)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom)
        .accessibilityHint(isLastPage ? "进入应用" : "下一页")
    }

    private func finish() {
        onContinue()
        dismiss()
    }
}

#Preview("半屏引导 · 插画") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AppWelcomeGuideView(onContinue: {})
        }
}

#Preview("半屏引导 · 暗色") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AppWelcomeGuideView(onContinue: {})
        }
        .preferredColorScheme(.dark)
}
