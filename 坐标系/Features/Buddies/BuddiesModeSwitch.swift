//
//  BuddiesModeSwitch.swift
//  坐标系
//
//  顶栏：标题菜单切找搭子 / 约陪玩 / 俱乐部 / 最近浏览；Trailing 筛选 Menu。
//

import SwiftUI
import CoordinateModels

/// 大标题菜单：三模式 + 有数据时的「最近浏览」（非 BuddyKind）。
struct BuddiesModeTitleMenu: View {
    @Binding var kind: BuddyKind
    var isBrowsingRecents: Bool
    var hasRecents: Bool
    var onSelectKind: (BuddyKind) -> Void
    var onSelectRecents: () -> Void

    var body: some View {
        Picker(BuddyBrowseCopy.ModeSwitch.picker, selection: selectionBinding) {
            ForEach(BuddyKind.allCases) { option in
                Label(option.stageTitle, systemImage: option.systemImage)
                    .tag(BuddiesBrowseSurface.kind(option))
            }
            if hasRecents {
                Label(BuddyBrowseCopy.recentsTitle, systemImage: "clock.arrow.circlepath")
                    .tag(BuddiesBrowseSurface.recents)
            }
        }
        .pickerStyle(.inline)
    }

    private var selectionBinding: Binding<BuddiesBrowseSurface> {
        Binding(
            get: {
                isBrowsingRecents ? .recents : .kind(kind)
            },
            set: { surface in
                switch surface {
                case .kind(let value):
                    onSelectKind(value)
                case .recents:
                    onSelectRecents()
                }
            }
        )
    }
}

/// Trailing：筛选 Menu（L1 即时）+ 深筛选入口在 Menu 内。
struct BuddiesModeSwitchToolbar: ToolbarContent {
    @Binding var filter: BuddyFilter
    @Binding var peopleSort: BuddyPeopleSort
    @Binding var bookingSort: BuddyBookingSort
    @Binding var clubSort: BuddyClubSort
    var hasActiveFilters: Bool
    var toolbarSystemImage: String
    var filterAccessibilityValue: String
    var onOpenDeepFilters: () -> Void

    private var menuHint: String {
        switch filter.kind {
        case .free: BuddyFilterCopy.freeMenuHint
        case .paid: BuddyFilterCopy.paidMenuHint
        case .clubs: BuddyFilterCopy.clubMenuHint
        }
    }

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                BuddyBrowseFilterMenuContent(
                    filter: $filter,
                    peopleSort: $peopleSort,
                    bookingSort: $bookingSort,
                    clubSort: $clubSort,
                    onOpenDeepFilters: onOpenDeepFilters
                )
            } label: {
                Label(
                    hasActiveFilters ? BuddyBrowseCopy.Toolbar.filterActive : BuddyBrowseCopy.Toolbar.filter,
                    systemImage: toolbarSystemImage
                )
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(
                hasActiveFilters ? BuddyBrowseCopy.Toolbar.filterActive : BuddyBrowseCopy.Toolbar.filter
            )
            .accessibilityHint(menuHint)
            .accessibilityValue(filterAccessibilityValue)
        }
    }
}

#Preview {
    struct Host: View {
        @State private var kind = BuddyKind.free
        @State private var filter = BuddyFilter()
        @State private var peopleSort = BuddyPeopleSort.recommended
        @State private var bookingSort = BuddyBookingSort.recommended
        @State private var clubSort = BuddyClubSort.active
        var body: some View {
            NavigationStack {
                Text(kind.stageTitle)
                    .platformTabRootScrollChrome(title: kind.stageTitle)
                    .platformTabRootTitleMenu {
                        BuddiesModeTitleMenu(
                            kind: $kind,
                            isBrowsingRecents: false,
                            hasRecents: true,
                            onSelectKind: { kind = $0 },
                            onSelectRecents: {}
                        )
                    }
                    .platformTabRootToolbar {
                        BuddiesModeSwitchToolbar(
                            filter: $filter,
                            peopleSort: $peopleSort,
                            bookingSort: $bookingSort,
                            clubSort: $clubSort,
                            hasActiveFilters: false,
                            toolbarSystemImage: "line.3.horizontal.decrease",
                            filterAccessibilityValue: "上海 · 5 km",
                            onOpenDeepFilters: {}
                        )
                    }
            }
        }
    }
    return Host()
}
