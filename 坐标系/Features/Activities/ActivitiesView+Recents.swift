//
//  ActivitiesView+Recents.swift
//  坐标系
//
//  活动发现「最近看过」表面：标题菜单入口，有记录才出现。
//

import SwiftUI
import CoordinateModels

extension ActivitiesView {
    var activityRecentRecords: [RecentBrowseRecord] {
        browseItems
            .filter { $0.kind == .activity }
            .prefix(ProfileRecentBrowseStore.maxItemsPerKind)
            .map(\.asRecord)
    }

    var hasActivityRecents: Bool { !activityRecentRecords.isEmpty }

    @ViewBuilder
    var recentsBrowseContent: some View {
        let rows: [(RecentBrowseRecord, Activity)] = activityRecentRecords.compactMap { record in
            guard let activity = model.activity(id: record.targetID) else { return nil }
            return (record, activity)
        }

        if rows.isEmpty {
            ContentUnavailableView {
                Label(ActivityBrowseCopy.recentsEmptyTitle, systemImage: "clock.arrow.circlepath")
            } description: {
                Text(ActivityBrowseCopy.recentsEmptyDescription)
            } actions: {
                Button(ActivityBrowseCopy.Empty.filteredAction) {
                    model.selectBrowseCategory(.forYou)
                }
                .activityPrimaryCTA(controlSize: .large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rows, id: \.0.id) { record, activity in
                    ActivityZoomNavigationLink(activity: activity, namespace: zoomNamespace) {
                        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                                Text(activity.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(record.subtitle.isEmpty ? activity.location : record.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Text(Formatters.conversationListTime(from: record.viewedAt))
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, PlatformMetrics.contentInset)
                        .padding(.vertical, PlatformMetrics.cardInfoSpacing)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, PlatformMetrics.sectionSpacing)
        }
    }
}
