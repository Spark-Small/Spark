//
//  BuddyDetailRouteView.swift
//  坐标系
//
//  搭子详情路由：免费 / 付费分流。
//

import SwiftUI
import CoordinateModels

struct BuddyDetailRouteView: View {
    let item: DiscoverBuddyItem
    var source: BuddyProfileSource = .discover
    /// 从群成员入口进入时展示 真实名（群昵称）
    var groupAlias: String? = nil

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(\.profileRecentBrowseStore) private var recentBrowseStore
    @Environment(\.dismiss) private var dismiss

    @State private var showReport = false
    @State private var confirmBlock = false
    @State private var peerContactRoute: PeerContactRoute?

    private var profileTitle: String {
        GroupNicknameDisplay.formatted(
            realName: item.profile.nickname,
            groupAlias: groupAlias
        )
    }

    private func greetTitle(for item: DiscoverBuddyItem) -> String {
        app.peerContactActionTitle(
            for: item.profile.nickname,
            context: .forBuddyItem(item)
        )
    }

    private func openGreet(for item: DiscoverBuddyItem) {
        peerContactRoute = app.openPeerContact(
            with: item.profile.nickname,
            context: .forBuddyItem(item)
        )
    }

    var body: some View {
        Group {
            switch item {
            case .free(let buddy):
                CircleBuddyDetailView(
                    buddy: buddy,
                    source: source,
                    groupAlias: groupAlias,
                    greetTitle: greetTitle(for: .free(buddy)),
                    onGreet: { openGreet(for: .free(buddy)) },
                    onInvite: {
                        guard app.requireIdentityAccess(source: .buddyBooking) else { return }
                        buddies.invite(buddy.profile.nickname)
                    }
                )
            case .paid(let companion):
                PaidCompanionDetailView(
                    companion: companion,
                    source: source,
                    groupAlias: groupAlias,
                    greetTitle: greetTitle(for: .paid(companion)),
                    onGreet: { openGreet(for: .paid(companion)) },
                    onQuickBook: { buddies.book(companion) },
                    onBookDay: { day in
                        buddies.book(companion, initialDay: day)
                    },
                    onBookService: { sku in
                        buddies.book(companion, serviceSKU: sku)
                    }
                )
            }
        }
        .navigationTitle(profileTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            switch item {
            case .free(let buddy):
                recentBrowseStore.record(buddy: buddy.profile)
            case .paid(let companion):
                recentBrowseStore.record(companion: companion)
            }
        }
        .peerContactDestination(route: $peerContactRoute)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button(BuddyDetailCopy.notInterested, systemImage: "eye.slash") {
                        buddies.hidePerson(nickname: item.profile.nickname)
                        dismiss()
                    }
                    Button(BuddyDetailCopy.report, systemImage: "exclamationmark.bubble", role: .destructive) {
                        showReport = true
                    }
                    Button(BuddyDetailCopy.block, systemImage: "hand.raised", role: .destructive) {
                        confirmBlock = true
                    }
                } label: {
                    Label(BuddyDetailCopy.moreMenu, systemImage: "ellipsis")
                }
                .platformNavigationBarItemChrome()
            }
        }
        .alert(BuddyDetailCopy.reportTitle(item.profile.nickname), isPresented: $showReport) {
            Button(BuddyDetailCopy.reportHarassment, role: .destructive) {
                submitBuddyReport(reason: BuddyDetailCopy.reportHarassment)
            }
            Button(BuddyDetailCopy.reportFakeProfile, role: .destructive) {
                submitBuddyReport(reason: BuddyDetailCopy.reportFakeProfile)
            }
            Button(BuddyDetailCopy.cancel, role: .cancel) {}
        } message: {
            Text(BuddyDetailCopy.reportMessage)
        }
        .alert(
            BuddyDetailCopy.blockTitle(item.profile.nickname),
            isPresented: $confirmBlock
        ) {
            Button(BuddyDetailCopy.block, role: .destructive) {
                app.blockUser(item.profile.nickname)
                dismiss()
            }
            Button(BuddyDetailCopy.cancel, role: .cancel) {}
        } message: {
            Text(BuddyDetailCopy.blockMessage)
        }
    }

    private func submitBuddyReport(reason: String) {
        let nickname = item.profile.nickname
        app.addModerationTicket(
            postID: item.id,
            title: nickname,
            reason: reason,
            targetKind: .person
        )
        buddies.hidePerson(nickname: nickname)
        buddies.flash(BuddyFeedbackCopy.reportSubmitted)
        dismiss()
    }
}

// MARK: - Free

