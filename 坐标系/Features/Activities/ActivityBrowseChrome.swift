//
//  ActivityBrowseChrome.swift
//  坐标系
//
//  活动发现顶栏：与其它 Tab 共用 platformTabRoot*
//  （navigationTitle + inlineLarge + toolbarTitleMenu + trailing 分组）。
//

import SwiftUI
import TipKit
import CoordinateModels

/// 大标题菜单：分类 + 有数据时的「最近看过」（非 ActivityCategory）。
struct ActivityBrowseCategoryTitleMenu: View {
    @Binding var category: ActivityCategory
    var isBrowsingRecents: Bool
    var hasRecents: Bool
    var onSelectCategory: (ActivityCategory) -> Void
    var onSelectRecents: () -> Void

    var body: some View {
        Picker(ActivityFilterCopy.categoryMenu, selection: selectionBinding) {
            ForEach(ActivityCategory.browseTitleCategories) { option in
                Label(option.title, systemImage: option.systemImage)
                    .tag(ActivitiesBrowseSurface.category(option))
            }
            if hasRecents {
                Label(ActivityBrowseCopy.recentsTitle, systemImage: "clock.arrow.circlepath")
                    .tag(ActivitiesBrowseSurface.recents)
            }
        }
        .pickerStyle(.inline)
        .accessibilityLabel(ActivityFilterCopy.categoryMenu)
    }

    private var selectionBinding: Binding<ActivitiesBrowseSurface> {
        Binding(
            get: {
                isBrowsingRecents ? .recents : .category(category)
            },
            set: { surface in
                switch surface {
                case .category(let value):
                    onSelectCategory(value)
                case .recents:
                    onSelectRecents()
                }
            }
        )
    }
}

/// 「最近看过」Trailing：退出临时表面，回到进入前的分类（系统 toolbar 文本钮，非 push 返回）。
struct ActivityBrowseRecentsExitToolbar: ToolbarContent {
    var previousCategoryTitle: String
    var onExit: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(ActivityBrowseCopy.recentsBack, action: onExit)
                .platformNavigationBarItemChrome()
                .accessibilityHint(ActivityBrowseCopy.recentsBackHint(previousCategoryTitle))
        }
    }
}

/// Trailing：筛选组 + 发起组（`ToolbarSpacer` 分隔）；图标系统原色。
struct ActivityBrowseTrailingToolbar: ToolbarContent {
    @Binding var quickFilters: Set<ActivityQuickFilter>
    @Binding var nearbyRadiusKM: Double?
    var onCompose: () -> Void

    private var hasActiveFilters: Bool {
        !quickFilters.isEmpty || nearbyRadiusKM != nil
    }

    private var toolbarSystemImage: String {
        ActivityQuickFilter.toolbarSystemImage(
            quickFilters: quickFilters,
            nearbyRadiusKM: nearbyRadiusKM
        )
    }

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                ActivityFilterMenuContent(
                    quickFilters: $quickFilters,
                    nearbyRadiusKM: $nearbyRadiusKM
                )
            } label: {
                Label(
                    hasActiveFilters
                        ? ActivityFilterCopy.menuTitleActive
                        : ActivityFilterCopy.menuTitle,
                    systemImage: toolbarSystemImage
                )
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(
                hasActiveFilters
                    ? ActivityFilterCopy.menuTitleActive
                    : ActivityFilterCopy.menuTitle
            )
            .accessibilityValue(
                ActivityFilterCopy.accessibilityValue(
                    quickFilters: quickFilters,
                    nearbyRadiusKM: nearbyRadiusKM
                )
            )
            .accessibilityHint(ActivityFilterCopy.menuHint)
            .popoverTip(ActivityFilterTip())
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(ActivityComposeCopy.createTitle, systemImage: "plus", action: onCompose)
                .platformNavigationBarItemChrome()
        }
    }
}
