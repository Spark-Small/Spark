//
//  ProfileMyActivitiesView.swift
//  坐标系
//
//  「我的活动」：右上角分类 Menu；横卡页边 / 卡距对齐活动发现竖列
// （`discoverBrowseContentInset` + `discoverCardSpacing` + `discoverBrowsePageColumn`）。
//

import SwiftUI
import CoordinateModels

struct ProfileMyActivitiesView: View {
    var initialCategory: ProfileMyActivitiesCopy.Category = .upcoming

    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @Namespace private var zoomNamespace
    @State private var category: ProfileMyActivitiesCopy.Category

    init(initialCategory: ProfileMyActivitiesCopy.Category = .upcoming) {
        self.initialCategory = initialCategory
        _category = State(initialValue: initialCategory)
    }

    private var visibleActivities: [Activity] {
        switch category {
        case .upcoming:
            libraryActivities.filter { !$0.isPast }.sorted { $0.date < $1.date }
        case .attending:
            // 已报名 + 候补（不含我发起的）；角标区分「已参加 / 已候补」。
            attendingActivities.sorted { $0.date < $1.date }
        case .hosting:
            activities.hostedActivities.sorted { $0.date < $1.date }
        case .past:
            libraryActivities.filter(\.isPast).sorted { $0.date > $1.date }
        }
    }

    private var libraryActivities: [Activity] {
        var byID: [Activity.ID: Activity] = [:]
        for activity in activities.joinedActivities {
            byID[activity.id] = activity
        }
        for activity in activities.waitlistedActivities {
            byID[activity.id] = activity
        }
        for activity in activities.hostedActivities {
            byID[activity.id] = activity
        }
        return Array(byID.values)
    }

    private var attendingActivities: [Activity] {
        var byID: [Activity.ID: Activity] = [:]
        for activity in activities.joinedActivities where !activities.isHost(activity) {
            byID[activity.id] = activity
        }
        for activity in activities.waitlistedActivities where !activities.isHost(activity) {
            byID[activity.id] = activity
        }
        return Array(byID.values)
    }

    var body: some View {
        Group {
            if visibleActivities.isEmpty {
                emptyContent
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PlatformMetrics.discoverCardSpacing) {
                        ForEach(visibleActivities) { activity in
                            activityCard(activity)
                        }
                    }
                    .discoverBrowseContentInset()
                    .discoverBrowsePageColumn()
                }
                .profileLibraryBrowseChrome()
            }
        }
        .navigationTitle(ProfileMyActivitiesCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProfileLibraryCategoryMenu(
                    selection: $category,
                    options: Array(ProfileMyActivitiesCopy.Category.allCases),
                    accessibilityLabel: ProfileMyActivitiesCopy.pickerAccessibility,
                    title: \.segmentTitle,
                    systemImage: \.systemImage,
                    tag: { $0 },
                    labelStyle: .textTitle(category.segmentTitle)
                )
            }
        }
        .activityZoomNavigationDestinationIfNeeded(fallback: zoomNamespace)
    }

    private var emptyContent: some View {
        ProfileLibraryEmptyView(
            title: category.emptyTitle,
            systemImage: category.emptySystemImage,
            description: category.emptyDescription
        ) {
            if category == .upcoming || category == .attending {
                Button(ProfileMyActivitiesCopy.browseDiscover) {
                    app.focusActivitiesDiscoverBrowse()
                }
            }
        }
    }

    @ViewBuilder
    private func activityCard(_ activity: Activity) -> some View {
        let hosting = activities.isHost(activity)
        let intent: ActivityZoomIntent = hosting ? .browseDetail : .participantPass
        ProfileMyActivitiesCard(
            activity: activity,
            zoomNamespace: zoomNamespace,
            intent: intent,
            badge: ProfileMyActivitiesStatusPresentation.badge(
                for: activity,
                isHost: hosting,
                isWaitlisted: activities.isWaitlisted(activity.id)
            )
        )
    }
}

#Preview {
    NavigationStack {
        ProfileMyActivitiesView()
    }
}
