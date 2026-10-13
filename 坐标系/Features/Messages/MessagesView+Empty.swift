//
//  MessagesView+Empty.swift
//  坐标系
//
//  收件箱空态：筛选空 / 仅屏蔽 / 真·空态 CTA。
//

import SwiftUI
import CoordinateModels

extension MessagesView {
    private var isBlockedOnlyEmpty: Bool {
        !model.isSearching
            && !isFilterEmptyOnly
            && visibleItems.isEmpty
            && !model.items.isEmpty
            && model.inboxBaseItems(blockedNames: blockedNames).isEmpty
    }

    @ViewBuilder
    var emptyContent: some View {
        Group {
            if model.isSearching {
                ContentUnavailableView.search(text: model.searchText)
            } else if isFilterEmptyOnly {
                ContentUnavailableView {
                    Label(MessagesCopy.filterEmptyTitle, systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    Text(MessagesCopy.filterEmptyDescription)
                } actions: {
                    Button(MessagesCopy.filterEmptyShowAll) {
                        inboxFilter = .all
                    }
                    Button(MessagesCopy.emptyInboxBrowseActivities) {
                        app.focusActivitiesDiscoverBrowse()
                    }
                    Button(MessagesCopy.emptyInboxMeetBuddies) {
                        app.pendingBuddiesRoute = .socialBrowse
                        app.selectedTab = .buddies
                    }
                }
            } else if isBlockedOnlyEmpty {
                ContentUnavailableView {
                    Label(MessagesCopy.blockedOnlyEmptyTitle, systemImage: "hand.raised")
                } description: {
                    Text(MessagesCopy.blockedOnlyEmptyDescription)
                } actions: {
                    Button(MessagesCopy.friendsListTitle) {
                        navigation.path.append(MessagesInboxRoute.friends)
                    }
                    Button(MessagesCopy.emptyInboxBrowseActivities) {
                        app.focusActivitiesDiscoverBrowse()
                    }
                    Button(MessagesCopy.emptyInboxMeetBuddies) {
                        app.pendingBuddiesRoute = .socialBrowse
                        app.selectedTab = .buddies
                    }
                }
            } else if model.isEmptyInbox || visibleItems.isEmpty {
                ContentUnavailableView {
                    Label(MessagesCopy.emptyInboxTitle, systemImage: "message")
                } description: {
                    Text(MessagesCopy.emptyInboxDescription)
                } actions: {
                    Button(MessagesCopy.friendsListTitle) {
                        navigation.path.append(MessagesInboxRoute.friends)
                    }

                    if model.strangerMailboxCount > 0 {
                        Button(MessagesCopy.emptyInboxOpenStrangers) {
                            showStrangerMailbox = true
                        }
                    }

                    Button(MessagesCopy.emptyInboxBrowseActivities) {
                        app.focusActivitiesDiscoverBrowse()
                    }

                    Button(MessagesCopy.emptyInboxMeetBuddies) {
                        app.pendingBuddiesRoute = .socialBrowse
                        app.selectedTab = .buddies
                    }
                }
            }
        }
        .platformContentUnavailablePageChrome()
    }
}
