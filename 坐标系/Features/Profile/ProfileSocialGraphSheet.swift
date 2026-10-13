//
//  ProfileSocialGraphSheet.swift
//  坐标系
//
//  「我的」头区折叠粉丝行 → Sheet：粉丝 / 关注分段（复用 ProfileSocialGraphView）。
//

import SwiftUI

enum ProfileSocialGraphSheetTab: String, CaseIterable, Identifiable, Hashable {
    case fans
    case following

    var id: String { rawValue }

    var kind: ProfileSocialGraphKind {
        switch self {
        case .fans: .fans
        case .following: .following
        }
    }

    var title: String {
        kind.navigationTitle
    }
}

struct ProfileSocialGraphSheet: View {
    @Environment(\.dismiss) private var dismiss

    var initialTab: ProfileSocialGraphSheetTab = .fans
    @State private var tab: ProfileSocialGraphSheetTab

    init(initialTab: ProfileSocialGraphSheetTab = .fans) {
        self.initialTab = initialTab
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionHeaderSpacing) {
                Picker(ProfileSocialCopy.graphSheetPickerAccessibility, selection: $tab) {
                    ForEach(ProfileSocialGraphSheetTab.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.top, PlatformMetrics.sectionHeaderSpacing)

                ProfileSocialGraphView(kind: tab.kind)
            }
            // 标题由 `ProfileSocialGraphView` 随分段切换（粉丝 / 关注）。
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ProfileSocialCopy.graphSheetDone, systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
        .independentNavigationSheetChrome()
        .platformSheet(.browser)
    }
}
