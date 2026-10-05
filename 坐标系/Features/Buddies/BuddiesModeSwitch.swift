//
//  BuddiesModeSwitch.swift
//  坐标系
//
//  顶栏 Trailing：筛选 Menu | 模式 Menu（找搭子 / 约陪玩 / 俱乐部 / 最近浏览）。
//  创建俱乐部在「我的 · 我的俱乐部」。
//

import SwiftUI
import CoordinateModels

/// 模式表面 Picker（供 Trailing Menu 内联）。
struct BuddiesBrowseSurfacePicker: View {
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

/// Trailing：筛选 → 模式 Menu（模式在筛选右侧）。
struct BuddiesModeSwitchToolbar: ToolbarContent {
    @Binding var filter: BuddyFilter
    @Binding var peopleSort: BuddyPeopleSort
    @Binding var bookingSort: BuddyBookingSort
    @Binding var clubSort: BuddyClubSort
    var isBrowsingRecents: Bool
    var hasRecents: Bool
    var hasActiveFilters: Bool
    var toolbarSystemImage: String
    var filterAccessibilityValue: String
    var onOpenDeepFilters: () -> Void
    var onSelectKind: (BuddyKind) -> Void
    var onSelectRecents: () -> Void

    private var menuHint: String {
        switch filter.kind {
        case .free: BuddyFilterCopy.freeMenuHint
        case .paid: BuddyFilterCopy.paidMenuHint
        case .clubs: BuddyFilterCopy.clubMenuHint
        }
    }

    private var currentSurface: BuddiesBrowseSurface {
        isBrowsingRecents ? .recents : .kind(filter.kind)
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

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                BuddiesBrowseSurfacePicker(
                    kind: $filter.kind,
                    isBrowsingRecents: isBrowsingRecents,
                    hasRecents: hasRecents,
                    onSelectKind: onSelectKind,
                    onSelectRecents: onSelectRecents
                )
            } label: {
                Label(currentSurface.title, systemImage: currentSurface.systemImage)
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(BuddyBrowseCopy.ModeSwitch.picker)
            .accessibilityHint(BuddyBrowseCopy.ModeSwitch.menuHint)
            .accessibilityValue(currentSurface.title)
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
                    .platformTabRootToolbar {
                        BuddiesModeSwitchToolbar(
                            filter: $filter,
                            peopleSort: $peopleSort,
                            bookingSort: $bookingSort,
                            clubSort: $clubSort,
                            isBrowsingRecents: false,
                            hasRecents: true,
                            hasActiveFilters: false,
                            toolbarSystemImage: "line.3.horizontal.decrease",
                            filterAccessibilityValue: "上海 · 5 km",
                            onOpenDeepFilters: {},
                            onSelectKind: { kind = $0; filter.kind = $0 },
                            onSelectRecents: {}
                        )
                    }
            }
        }
    }
    return Host()
}
