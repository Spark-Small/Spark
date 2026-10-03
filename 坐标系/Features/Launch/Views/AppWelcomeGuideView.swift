//
//  AppWelcomeGuideView.swift
//  坐标系
//
//  首启意图选择：系统导航标题 + 次要胶囊；高度按内容 `.height`。
//

import SwiftUI

enum AppWelcomeIntent: String, CaseIterable, Identifiable {
    case findActivity
    case meetPeople
    case browse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .findActivity: "参加喜好活动"
        case .meetPeople: "认识新的搭子"
        case .browse: "一个人先逛逛"
        }
    }

    /// 优先 `.fill`，便于 `platformContentSymbolStyle()`（multicolor）出彩。
    var systemImage: String {
        switch self {
        case .findActivity: "calendar.circle.fill"
        case .meetPeople: "person.2.circle.fill"
        case .browse: "square.grid.2x2.fill"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .findActivity: "打开活动推荐"
        case .meetPeople: "打开搭子墙"
        case .browse: "打开活动发现"
        }
    }

    var landingTab: AppTab {
        switch self {
        case .findActivity, .browse: .activities
        case .meetPeople: .buddies
        }
    }
}

enum AppWelcomeGuideCopy {
    static let storageKey = "app.hasSeenWelcomeGuide"
    static let skip = "跳过"
    static let title = "你想先做点什么？"
    static let findActivityConfirmedGeneric = "已为你打开活动推荐"
    static let browseConfirmed = "已为你打开活动发现"
    static let meetPeopleConfirmed = "已为你打开同城同好"

    static func filterConfirmed(_ filterName: String) -> String {
        "已为你筛选\(filterName)的活动"
    }
}

struct AppWelcomeGuideView: View {
    var onContinue: (AppWelcomeIntent) -> Void

    @Environment(\.dismiss) private var dismiss
    /// 内容区理想高度；sheet 用 `.height(content + 导航栏)`，iPhone 上 `.fitted` 会掉成 `.large`。
    @State private var contentHeight: CGFloat = 0
    @State private var selectionPulse = 0

    private var sheetHeight: CGFloat {
        let chrome: CGFloat = 72 // inline 导航栏 + grabber
        guard contentHeight > 0 else { return 300 }
        return contentHeight + chrome
    }

    var body: some View {
        NavigationStack {
            VStack {
                ForEach(AppWelcomeIntent.allCases) { intent in
                    Button {
                        selectionPulse += 1
                        finish(with: intent)
                    } label: {
                        Label {
                            Text(intent.title)
                        } icon: {
                            Image(systemName: intent.systemImage)
                                .platformContentSymbolStyle()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .activitySecondaryCTA(controlSize: .large)
                    .accessibilityHint(intent.accessibilityHint)
                }
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .sensoryFeedback(.selection, trigger: selectionPulse)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: WelcomeIntentContentHeightKey.self,
                        value: proxy.size.height
                    )
                }
            }
            .onPreferenceChange(WelcomeIntentContentHeightKey.self) { contentHeight = $0 }
            .navigationTitle(AppWelcomeGuideCopy.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppWelcomeGuideCopy.skip) {
                        finish(with: .browse)
                    }
                }
            }
        }
        .platformSheet(.light(.height(sheetHeight)))
    }

    private func finish(with intent: AppWelcomeIntent) {
        onContinue(intent)
        dismiss()
    }
}

private enum WelcomeIntentContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview("意图引导") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AppWelcomeGuideView(onContinue: { _ in })
        }
}
