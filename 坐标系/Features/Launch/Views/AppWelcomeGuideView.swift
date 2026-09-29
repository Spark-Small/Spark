//
//  AppWelcomeGuideView.swift
//  坐标系
//
//  首启半屏：意图选择（找活动 / 找同好 / 先逛逛）。
//

import SwiftUI
import CoordinateModels

enum AppWelcomeIntent: String, CaseIterable, Identifiable {
    case findActivity
    case meetPeople
    case browse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .findActivity: "找能参加的活动"
        case .meetPeople: "认识兴趣相同的人"
        case .browse: "先随便逛逛"
        }
    }

    var systemImage: String {
        switch self {
        case .findActivity: "calendar.badge.clock"
        case .meetPeople: "person.2.fill"
        case .browse: "sparkles"
        }
    }

    var landingTab: AppTab {
        switch self {
        case .findActivity, .browse: .activities
        case .meetPeople: .buddies
        }
    }

    /// 欢迎意图写入资料兴趣（bootstrap 用）。
    var profileInterests: [String] {
        switch self {
        case .findActivity:
            ["同城局", "探店", "骑行", "羽毛球"]
        case .meetPeople:
            ["认识同好", "搭子", "羽毛球", "桌游"]
        case .browse:
            SampleData.currentUserInterests
        }
    }
}

enum AppWelcomeGuideCopy {
    static let storageKey = "app.hasSeenWelcomeGuide"
    static let skip = "跳过"
    static let title = "你想先做点什么？"
    static let subtitle = "选一个方向，我们会帮你更快开始"
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

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                    Text(AppWelcomeGuideCopy.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(AppWelcomeGuideCopy.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, PlatformMetrics.sectionSpacing)

                VStack(spacing: PlatformMetrics.cardFooterSpacing) {
                    ForEach(AppWelcomeIntent.allCases) { intent in
                        Button {
                            finish(with: intent)
                        } label: {
                            Label(intent.title, systemImage: intent.systemImage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                                .padding(.horizontal, PlatformMetrics.contentInset)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, PlatformMetrics.contentInset)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppWelcomeGuideCopy.skip) {
                        finish(with: .browse)
                    }
                }
            }
        }
        .tint(PlatformAction.brandAccent)
        .platformSheet(.confirm)
    }

    private func finish(with intent: AppWelcomeIntent) {
        onContinue(intent)
        dismiss()
    }
}

#Preview("意图引导") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AppWelcomeGuideView(onContinue: { _ in })
        }
}
