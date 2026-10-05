//
//  ProfileLibraryChrome.swift
//  坐标系
//
//  「我的」内容库共用：分类筛选 Menu + 页面级空态（ContentUnavailableView）。
//

import SwiftUI

/// 顶栏分类 Menu 的 label 形态（活动用文字；陪玩/俱乐部用漏斗图标，对齐搭子）。
enum ProfileLibraryFilterLabelStyle: Equatable {
    case textTitle(String)
    case filterIcon(systemImage: String, accessibilityTitle: String)
}

struct ProfileLibraryCategoryMenu<Selection: Hashable, Option: Identifiable & Hashable>: View {
    @Binding var selection: Selection
    let options: [Option]
    let accessibilityLabel: String
    var accessibilityHint: String? = nil
    let title: (Option) -> String
    let systemImage: (Option) -> String
    let tag: (Option) -> Selection
    let labelStyle: ProfileLibraryFilterLabelStyle

    var body: some View {
        Menu {
            Picker(accessibilityLabel, selection: $selection) {
                ForEach(options) { option in
                    Label(title(option), systemImage: systemImage(option))
                        .tag(tag(option))
                }
            }
            .pickerStyle(.inline)
        } label: {
            switch labelStyle {
            case .textTitle(let title):
                // 文字按钮：勿用 Label（toolbar 常收成 iconOnly）。
                Text(title)
                    .font(.body.weight(.medium))
            case .filterIcon(let systemImage, let accessibilityTitle):
                Label(accessibilityTitle, systemImage: systemImage)
            }
        }
        .modifier(ProfileLibraryFilterChromeModifier(usesBarChrome: usesBarChrome))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .modifier(ProfileLibraryOptionalHintModifier(hint: accessibilityHint))
    }

    private var usesBarChrome: Bool {
        if case .filterIcon = labelStyle { return true }
        return false
    }

    private var accessibilityValue: String {
        guard let selected = options.first(where: { tag($0) == selection }) else { return "" }
        return title(selected)
    }
}

private struct ProfileLibraryOptionalHintModifier: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        if let hint, !hint.isEmpty {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

private struct ProfileLibraryFilterChromeModifier: ViewModifier {
    let usesBarChrome: Bool

    func body(content: Content) -> some View {
        if usesBarChrome {
            content.platformNavigationBarItemChrome()
        } else {
            content
        }
    }
}

/// 库页空态：官方 ContentUnavailableView + 页面铺满居中；CTA 仅裸 Button。
struct ProfileLibraryEmptyView<Actions: View>: View {
    let title: String
    let systemImage: String
    let description: String
    @ViewBuilder var actions: () -> Actions

    init(
        title: String,
        systemImage: String,
        description: String,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actions = actions
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            actions()
        }
        .platformContentUnavailablePageChrome()
    }
}

extension ProfileLibraryEmptyView where Actions == EmptyView {
    init(title: String, systemImage: String, description: String) {
        self.init(title: title, systemImage: systemImage, description: description) {
            EmptyView()
        }
    }
}
