//
//  BuddiesView+Recents.swift
//  坐标系
//
//  搭子「最近浏览」表面：标题菜单（俱乐部下方），有记录才出现。
//

import SwiftUI
import CoordinateModels

extension BuddiesView {
    private static let buddiesRecentKinds: Set<RecentBrowseKind> = [.buddy, .companion, .club]

    var buddiesRecentRecords: [RecentBrowseRecord] {
        browseItems
            .filter { Self.buddiesRecentKinds.contains($0.kind) }
            .prefix(ProfileRecentBrowseStore.maxItemsPerKind)
            .map(\.asRecord)
    }

    var hasBuddiesRecents: Bool { !buddiesRecentRecords.isEmpty }

    func selectBrowseKind(_ kind: BuddyKind) {
        isBrowsingRecents = false
        model.filter.kind = kind
    }

    func selectBrowseRecents() {
        isBrowsingRecents = true
    }

    var browseNavigationTitle: String {
        isBrowsingRecents ? BuddyBrowseCopy.recentsTitle : browseKind.stageTitle
    }

    @ViewBuilder
    var recentsBrowseContent: some View {
        let people = buddiesRecentRecords.filter { $0.kind == .buddy || $0.kind == .companion }
        let clubs = buddiesRecentRecords.filter { $0.kind == .club }

        if people.isEmpty, clubs.isEmpty {
            ContentUnavailableView {
                Label(BuddyBrowseCopy.recentsEmptyTitle, systemImage: "clock.arrow.circlepath")
            } description: {
                Text(BuddyBrowseCopy.recentsEmptyDescription)
            } actions: {
                Button(BuddyBrowseCopy.Empty.relaxFilters) {
                    selectBrowseKind(.free)
                }
                .activityPrimaryCTA(controlSize: .large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
        } else {
            LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                if !people.isEmpty {
                    DiscoverBrowseSection(title: BuddyBrowseCopy.recentsSectionPeople) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(people) { record in
                                buddiesRecentPersonRow(record)
                            }
                        }
                    }
                }
                if !clubs.isEmpty {
                    DiscoverBrowseSection(title: BuddyBrowseCopy.recentsSectionClubs) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(clubs) { record in
                                buddiesRecentClubRow(record)
                            }
                        }
                    }
                }
            }
            .padding(.top, PlatformMetrics.sectionSpacing)
        }
    }

    @ViewBuilder
    private func buddiesRecentPersonRow(_ record: RecentBrowseRecord) -> some View {
        if let item = model.discoverItem(id: record.targetID) {
            NavigationLink(value: BuddyZoomRoute(item: item)) {
                recentRowLabel(
                    title: record.title,
                    subtitle: record.subtitle,
                    viewedAt: record.viewedAt
                )
            }
            .buttonStyle(.plain)
        } else {
            recentRowLabel(
                title: record.title,
                subtitle: record.subtitle,
                viewedAt: record.viewedAt
            )
            .opacity(0.55)
        }
    }

    @ViewBuilder
    private func buddiesRecentClubRow(_ record: RecentBrowseRecord) -> some View {
        if let circle = model.circle(id: record.targetID) {
            Button {
                navigation.openCircle(circle)
            } label: {
                recentRowLabel(
                    title: record.title,
                    subtitle: record.subtitle,
                    viewedAt: record.viewedAt
                )
            }
            .buttonStyle(.plain)
        } else {
            recentRowLabel(
                title: record.title,
                subtitle: record.subtitle,
                viewedAt: record.viewedAt
            )
            .opacity(0.55)
        }
    }

    private func recentRowLabel(title: String, subtitle: String, viewedAt: Date) -> some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Text(Formatters.conversationListTime(from: viewedAt))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
        .padding(.vertical, PlatformMetrics.cardInfoSpacing)
        .contentShape(Rectangle())
    }
}
