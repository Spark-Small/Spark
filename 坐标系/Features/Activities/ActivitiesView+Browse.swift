//
//  ActivitiesView+Browse.swift
//  坐标系
//
//  活动发现货架与软启动广场入口。
//

import SwiftUI
import CoordinateModels

extension ActivitiesView {
    @ViewBuilder
    var browseContent: some View {
        // 精选 Hero 与货架同一 LazyVStack，分区间距统一为 sectionSpacing（一条垂直节奏）。
        LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
            if model.showsBrowseModules, let spotlight = model.spotlightActivity {
                ActivityFeaturedSpotlightSection(
                    activity: spotlight,
                    zoomNamespace: zoomNamespace,
                    onJoin: join
                )
                .activityZoomSlot("spotlight")
            }

            ForEach(model.recommendationShelves) { shelf in
                ActivityBrowseShelfSection(
                    shelf: shelf,
                    zoomNamespace: zoomNamespace,
                    onJoin: join
                )
                .activityZoomSlot("shelf-\(shelf.id)")
            }

            if app.productLifecycleStore.shouldMergeCommunityIntoActivitiesTab {
                communityFeedEntry
            }
        }
    }

    var communityFeedEntry: some View {
        DiscoverBrowseSection {
            DiscoverSectionTitleRow(
                title: CommunityBrowseCopy.embeddedEntryTitle,
                subtitle: CommunityBrowseCopy.embeddedEntrySubtitle
            )
        } content: {
            NavigationLink(value: ActivitiesBrowseRoute.communityFeed) {
                Label {
                    VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                        Text(CommunityBrowseCopy.embeddedEntryTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(communityPreviewSubtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } icon: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3.weight(.semibold))
                        .platformContentSymbolStyle()
                }
                .labelStyle(.titleAndIcon)
                .padding(PlatformMetrics.sectionHeaderSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .platformThinMaterialBackground(in: PlatformMetrics.cardShape)
            }
            .discoverBrowseContentInset()
        }
    }

    var communityPreviewSubtitle: String {
        let count = app.community.items.count
        if count == 0 {
            return CommunityBrowseCopy.embeddedEntryEmptyPreview
        }
        return CommunityBrowseCopy.embeddedEntryCountPreview(count)
    }

    var activeFilterCount: Int {
        model.quickFilters.count + (model.nearbyFilterRadiusKM != nil ? 1 : 0)
    }

    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    @ViewBuilder
    var emptyState: some View {
        let filtered = hasActiveFilters || model.selectedCategory != .forYou
        ContentUnavailableView {
            Label(
                filtered ? ActivityBrowseCopy.Empty.filteredTitle : ActivityBrowseCopy.Empty.title,
                systemImage: filtered ? "line.3.horizontal.decrease" : "calendar.badge.plus"
            )
        } description: {
            Text(
                filtered
                    ? ActivityBrowseCopy.Empty.filteredDescription
                    : ActivityBrowseCopy.Empty.description
            )
        } actions: {
            if filtered {
                Button(ActivityBrowseCopy.Empty.filteredAction) {
                    model.clearBrowseQuery()
                    model.selectBrowseCategory(.forYou)
                }
                .activityPrimaryCTA(controlSize: .large)
            } else {
                Button(ActivityBrowseCopy.Empty.action, action: beginCompose)
                    .activityPrimaryCTA(controlSize: .large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }
}
