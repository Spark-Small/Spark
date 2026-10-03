//
//  BuddiesView+Empty.swift
//  坐标系
//
//  搭子发现分区 / 全页空态。
//

import SwiftUI
import CoordinateModels

extension BuddiesView {
    func sectionEmptyMessage(for pool: BuddyBrowsePool) -> String {
        let filtered = model.hasActiveBrowseFilters
        let locating = model.usesSystemLocation
            && (model.locatedPlaceName == nil || model.locatedPlaceName?.isEmpty == true)

        if filtered {
            return pool == .paid ? BuddyBrowseCopy.Empty.noPaidFiltered : BuddyBrowseCopy.Empty.noFreeFiltered
        }
        if locating {
            return BuddyBrowseCopy.Empty.locatingTitle
        }
        return pool == .paid ? BuddyBrowseCopy.Empty.noPaidNearby : BuddyBrowseCopy.Empty.nearbyEmptyTitle
    }

    @ViewBuilder
    func sectionEmptyState(message: String, showsFilterAction: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsFilterAction {
                Button(BuddyBrowseCopy.Empty.adjustFilters) {
                    showFilterSheet = true
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(PlatformAction.brandAccent)
            }
        }
        .discoverBrowseContentInset()
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
    }

    var combinedEmptyState: some View {
        let filtered = model.hasActiveBrowseFilters
        let locating = model.usesSystemLocation
            && (model.locatedPlaceName == nil || model.locatedPlaceName?.isEmpty == true)
        let supplyPending = !model.sampleCatalogEnabled && !filtered && !locating

        return ContentUnavailableView {
            Label(
                filtered
                    ? BuddyBrowseCopy.Empty.noMatchTitle
                    : (locating
                        ? BuddyBrowseCopy.Empty.locatingTitle
                        : (supplyPending
                            ? BuddiesSupplyPolicy.discoverEmptyTitle
                            : BuddyBrowseCopy.Empty.nearbyEmptyTitle)),
                systemImage: filtered
                    ? "magnifyingglass"
                    : (locating
                        ? "location.fill"
                        : (supplyPending ? "person.2.slash" : "mappin.and.ellipse"))
            )
        } description: {
            Text(
                filtered
                    ? BuddyBrowseCopy.Empty.noMatchBody
                    : (locating
                        ? BuddyBrowseCopy.Empty.locatingBody
                        : (supplyPending
                            ? BuddiesSupplyPolicy.discoverEmptyDescription
                            : BuddyBrowseCopy.Empty.nearbyEmptyBody))
            )
        } actions: {
            if filtered {
                Button(BuddyBrowseCopy.Empty.clearFilters) {
                    model.resetBrowseFilters()
                    peopleSort = .recommended
                    bookingSort = .recommended
                }
                .activityPrimaryCTA(controlSize: .large)
                Button(BuddyBrowseCopy.Empty.adjustFilters) {
                    showFilterSheet = true
                }
                .activitySecondaryCTA(controlSize: .large)
            } else if locating {
                Button(BuddyBrowseCopy.Empty.pickCity) {
                    showFilterSheet = true
                }
                .activityPrimaryCTA(controlSize: .large)
            } else if supplyPending {
                Button(BuddiesSupplyPolicy.browseActivitiesCTA) {
                    app.selectedTab = .activities
                }
                .activityPrimaryCTA(controlSize: .large)
                Button(BuddiesSupplyPolicy.createClubCTA) {
                    app.selectedTab = .profile
                    model.presentation.beginComposeClub()
                }
                .activitySecondaryCTA(controlSize: .large)
            } else {
                Button(BuddyBrowseCopy.Empty.relaxFilters) {
                    showFilterSheet = true
                }
                .activityPrimaryCTA(controlSize: .large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }
}
