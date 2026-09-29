//
//  ActivityBrowseQuickFilterBar.swift
//  坐标系
//
//  活动发现页快捷筛选 chip（本周末 / 今天 / 免费）。
//

import SwiftUI
import CoordinateModels

struct ActivityBrowseQuickFilterBar: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(LocationService.self) private var location

    var body: some View {
        PlatformFilterChipBar {
            ForEach(ActivityQuickFilter.browseChipOrder) { filter in
                ActivityQuickFilterChip(
                    filter: filter,
                    isSelected: model.quickFilters.contains(filter),
                    highlightToken: model.quickFilterHighlightToken,
                    isHighlighted: model.lastHighlightedQuickFilter == filter
                ) {
                    if filter == .nearby, !location.isAuthorized {
                        location.promptWhenInUseIfNeeded()
                    }
                    PlatformMotion.withAnimation(.snappy) {
                        model.toggleQuickFilter(filter)
                    }
                }
            }
        }
        .padding(.bottom, PlatformMetrics.sectionHeaderSpacing)
    }
}

private struct ActivityQuickFilterChip: View {
    let filter: ActivityQuickFilter
    let isSelected: Bool
    let highlightToken: Int
    let isHighlighted: Bool
    let onTap: () -> Void

    @State private var highlightPulse = 0

    var body: some View {
        PlatformFilterChipButton(
            title: filter.rawValue,
            systemImage: filter.systemImage,
            isSelected: isSelected,
            action: onTap
        )
        .platformStateFeedback($highlightPulse)
        .onChange(of: highlightToken) { _, newValue in
            guard newValue > 0, isHighlighted else { return }
            highlightPulse += 1
        }
    }
}
