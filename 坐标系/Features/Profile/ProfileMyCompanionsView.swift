//
//  ProfileMyCompanionsView.swift
//  坐标系
//
//  「我的陪玩」：Trailing 筛选 Menu 对齐搭子；双列小卡对齐发现网格
// （`personGridColumnCount` + `discoverCardSpacing` + `discoverBrowseContentInset`）。
//

import SwiftUI
import CoordinateModels

struct ProfileMyCompanionsView: View {
    var initialCategory: ProfileMyCompanionsCopy.Category = .upcoming

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @State private var category: ProfileMyCompanionsCopy.Category

    init(initialCategory: ProfileMyCompanionsCopy.Category = .upcoming) {
        self.initialCategory = initialCategory
        _category = State(initialValue: initialCategory)
    }

    private var visibleRecords: [BuddyBookingRecord] {
        let filtered = buddies.bookingRecords.filter {
            ProfileMyCompanionsStatusPresentation.matches($0, category: category)
        }
        switch category {
        case .upcoming, .pending, .active:
            return filtered.sorted { $0.scheduledAt < $1.scheduledAt }
        case .past:
            return filtered.sorted { $0.scheduledAt > $1.scheduledAt }
        }
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: PlatformMetrics.discoverCardSpacing),
            count: PlatformMetrics.personGridColumnCount
        )
    }

    var body: some View {
        Group {
            if visibleRecords.isEmpty {
                emptyContent
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: PlatformMetrics.discoverCardSpacing) {
                        ForEach(visibleRecords) { record in
                            companionCard(record)
                        }
                    }
                    .discoverBrowseContentInset()
                    .discoverBrowsePageColumn()
                }
                .profileLibraryBrowseChrome()
            }
        }
        .navigationTitle(ProfileMyCompanionsCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProfileLibraryCategoryMenu(
                    selection: $category,
                    options: Array(ProfileMyCompanionsCopy.Category.allCases),
                    accessibilityLabel: ProfileMyCompanionsCopy.pickerAccessibility,
                    accessibilityHint: ProfileMyCompanionsCopy.filterMenuHint,
                    title: \.segmentTitle,
                    systemImage: \.systemImage,
                    tag: { $0 },
                    labelStyle: .filterIcon(
                        systemImage: category.toolbarSystemImage,
                        accessibilityTitle: category.isFilterActive
                            ? ProfileMyCompanionsCopy.Toolbar.filterActive
                            : ProfileMyCompanionsCopy.Toolbar.filter
                    )
                )
            }
        }
    }

    private var emptyContent: some View {
        ProfileLibraryEmptyView(
            title: category.emptyTitle,
            systemImage: category.emptySystemImage,
            description: category.emptyDescription
        ) {
            if category == .upcoming || category == .pending {
                Button(ProfileMyCompanionsCopy.browseDiscover) {
                    app.pendingBuddiesRoute = .paidBrowse
                    app.selectedTab = .buddies
                }
            }
        }
    }

    private func companionCard(_ record: BuddyBookingRecord) -> some View {
        ProfileMyCompanionsCard(
            record: record,
            photo: buddies.item(
                for: record.companionNickname,
                userID: record.companionUserID
            )?.profile.coverPhoto,
            badge: ProfileMyCompanionsStatusPresentation.badge(for: record)
        )
    }
}

#Preview {
    NavigationStack {
        ProfileMyCompanionsView()
    }
}
