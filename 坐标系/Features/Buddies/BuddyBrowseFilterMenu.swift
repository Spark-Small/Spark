//
//  BuddyBrowseFilterMenu.swift
//  坐标系
//
//  三模式 L1 筛选 Menu：找搭子 / 约陪玩 / 俱乐部条件分流（对齐探探·比心·Meetup）。
//

import SwiftUI
import CoordinateModels

/// Menu 正文：按 `filter.kind` 展示不同即时条件 + 深筛选入口。
struct BuddyBrowseFilterMenuContent: View {
    @Binding var filter: BuddyFilter
    @Binding var peopleSort: BuddyPeopleSort
    @Binding var bookingSort: BuddyBookingSort
    @Binding var clubSort: BuddyClubSort
    var onOpenDeepFilters: () -> Void

    var body: some View {
        switch filter.kind {
        case .free:
            freeMenuSections
        case .paid:
            paidMenuSections
        case .clubs:
            clubMenuSections
        }

        Section {
            Button(BuddyFilterCopy.moreFilters, systemImage: "slider.horizontal.3") {
                Task { @MainActor in
                    onOpenDeepFilters()
                }
            }
        }
    }

    // MARK: - 找搭子（社交：排序 · 性别）

    @ViewBuilder
    private var freeMenuSections: some View {
        Section {
            Picker(BuddyFilterCopy.peopleSortHeader, selection: $peopleSort) {
                Text(BuddyFilterCopy.peopleSortRecommended).tag(BuddyPeopleSort.recommended)
                Text(BuddyFilterCopy.peopleSortActive).tag(BuddyPeopleSort.active)
            }
        }

        Section {
            genderPicker
        }
    }

    // MARK: - 约陪玩（交易：排序 · 可约 · 服务 · 性别）

    @ViewBuilder
    private var paidMenuSections: some View {
        Section {
            Picker(BuddyFilterCopy.bookingSortHeader, selection: $bookingSort) {
                ForEach(BuddyBookingSort.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Toggle(BuddyBrowseCopy.availableOnlyChip, isOn: $filter.availableOnly)
        }

        Section {
            Picker(BuddyPaidBrowseCopy.filterServiceTypeTitle, selection: serviceTypeBinding) {
                Text(BuddyPaidBrowseCopy.serviceTypeAll).tag(CompanionServiceType?.none)
                ForEach(CompanionServiceType.allCases) { type in
                    Label(type.rawValue, systemImage: type.systemImage)
                        .tag(CompanionServiceType?.some(type))
                }
            }
        }

        Section {
            genderPicker
        }
    }

    // MARK: - 俱乐部（组织：排序 · 主题）

    @ViewBuilder
    private var clubMenuSections: some View {
        Section {
            Picker(BuddyFilterCopy.clubSortHeader, selection: $clubSort) {
                ForEach(BuddyClubSort.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }

        Section {
            Picker(BuddyFilterCopy.clubTopicHeader, selection: clubTopicBinding) {
                Text(BuddyFilterCopy.clubTopicAny).tag(String?.none)
                ForEach(ClubTopicOption.allCases) { topic in
                    Label(topic.rawValue, systemImage: topic.systemImage)
                        .tag(String?.some(topic.rawValue))
                }
            }
        }
    }

    private var genderPicker: some View {
        Picker(BuddyFilterCopy.genderHeader, selection: genderBinding) {
            Text(BuddyFilterCopy.genderAny).tag(BuddyGender?.none)
            Text(BuddyFilterCopy.genderFemale).tag(BuddyGender?.some(.female))
            Text(BuddyFilterCopy.genderMale).tag(BuddyGender?.some(.male))
        }
    }

    private var genderBinding: Binding<BuddyGender?> {
        Binding(
            get: { filter.gender },
            set: { filter.gender = $0 }
        )
    }

    private var serviceTypeBinding: Binding<CompanionServiceType?> {
        Binding(
            get: { filter.serviceType },
            set: { filter.serviceType = $0 }
        )
    }

    private var clubTopicBinding: Binding<String?> {
        Binding(
            get: { filter.clubTopic },
            set: { filter.clubTopic = $0 }
        )
    }
}
