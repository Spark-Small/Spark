//
//  BuddyDetailViews.swift
//  坐标系
//
//  搭子详情：Form 规范对齐活动详情；同好 / 陪玩完整资料展示。
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
                    onInvite: { buddies.invite(buddy.profile.nickname) }
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
        .peerContactDestination(route: $peerContactRoute)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("不感兴趣", systemImage: "eye.slash") {
                        buddies.hidePerson(nickname: item.profile.nickname)
                        dismiss()
                    }
                    Button("举报", systemImage: "exclamationmark.bubble", role: .destructive) {
                        showReport = true
                    }
                    Button("拉黑", systemImage: "hand.raised", role: .destructive) {
                        confirmBlock = true
                    }
                } label: {
                    Label("更多", systemImage: "ellipsis")
                }
            }
        }
        .alert("举报 \(item.profile.nickname)", isPresented: $showReport) {
            Button("骚扰或不适内容", role: .destructive) {
                submitBuddyReport(reason: "骚扰或不适内容")
            }
            Button("虚假资料", role: .destructive) {
                submitBuddyReport(reason: "虚假资料")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("选择举报原因。我们会尽快核查。")
        }
        .alert(
            "拉黑 \(item.profile.nickname)？",
            isPresented: $confirmBlock
        ) {
            Button("拉黑", role: .destructive) {
                app.blockUser(item.profile.nickname)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("拉黑后将不再收到对方的互动与消息。")
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
        buddies.flash("已提交举报，并减少推荐")
        dismiss()
    }
}

// MARK: - Free

struct CircleBuddyDetailView: View {
    let buddy: CircleBuddy
    var source: BuddyProfileSource = .discover
    var groupAlias: String? = nil
    var greetTitle = BuddyDetailCopy.greet
    var onGreet: () -> Void
    var onInvite: () -> Void

    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app

    private var relatedActivities: [Activity] {
        Array(
            activities.activities(matchingTitles: buddy.relatedActivityTitles)
                .prefix(ActivityRelatedRecommender.displayLimit)
        )
    }

    var body: some View {
        let matchSection = BuddyDetailMatchSection(profile: buddy.profile)

        Form {
            // Meetup 式：封面 → 身份（含简介）→ 共同点 → 基本资料 → 圈子/档期 → 信任档案
            Section {
                BuddyDetailHeroGallery(profile: buddy.profile)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if let line = source.contextLine {
                Section {
                    BuddyDetailSourceRow(line: line, source: source)
                } header: {
                    Text(BuddyMemberCopy.sourceSectionTitle)
                }
            }

            Section {
                BuddyDetailProfileHeader(
                    profile: buddy.profile,
                    config: BuddyDetailProfileHeaderFactory.free(buddy: buddy),
                    groupAlias: groupAlias,
                    showsFollow: true,
                    isFollowing: app.isFollowing(buddy.profile.nickname),
                    onToggleFollow: { app.toggleFollow(buddy.profile.nickname) }
                )
            }

            if buddy.profile.hasVoiceIntro {
                Section {
                    BuddyPublicVoiceIntroRow(profile: buddy.profile)
                } header: {
                    Text(BuddyVoiceIntroCopy.publicSectionTitle)
                }
            }

            Section {
                matchSection
            } header: {
                Text(matchSection.sectionTitle)
            }

            Section {
                BuddyDetailBasicInfoSection(profile: buddy.profile)
            } header: {
                Text(BuddyDetailCopy.basicInfoTitle)
            }

            Section {
                BuddyDetailCircleRow(
                    circleName: buddy.circleName,
                    topic: buddy.topic,
                    profileSource: source
                )
            } header: {
                Text(BuddyDetailCopy.circleTitle)
            }

            Section {
                BuddyDetailScheduleSection(
                    slots: buddy.scheduleSlots,
                    allowsBooking: !buddy.scheduleSlots.isEmpty,
                    scheduleHint: BuddyBookingFlowCopy.freeScheduleHint,
                    onSelectBookableDay: { _ in onInvite() }
                )
            } header: {
                Text(BuddyDetailCopy.scheduleTitle)
            }

            TrustPublicProfileSections(
                nickname: buddy.profile.nickname,
                currentUserName: app.user.name,
                buddyItem: .free(buddy),
                compact: false
            )

            if !relatedActivities.isEmpty {
                Section {
                    DetailRelatedActivitiesRail(activities: relatedActivities)
                } header: {
                    Text(BuddyDetailCopy.relatedTitle)
                } footer: {
                    Text(BuddyDetailCopy.relatedFooter)
                }
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbarBackground(.hidden, for: .navigationBar)
        .platformDetailBottomBar {
            BuddyDetailActionBar(
                inviteEnabled: true,
                inviteTitle: BuddyDetailCopy.invite,
                greetTitle: greetTitle,
                onGreet: onGreet,
                onInvite: onInvite
            )
        }
    }
}

// MARK: - Paid

struct PaidCompanionDetailView: View {
    let companion: PaidCompanion
    var source: BuddyProfileSource = .discover
    var groupAlias: String? = nil
    var greetTitle = BuddyDetailCopy.greet
    var onGreet: () -> Void
    var onQuickBook: () -> Void
    var onBookDay: ((Date) -> Void)? = nil
    var onBookService: ((BuddyCompanionServiceSKU) -> Void)? = nil

    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @State private var selectedTab: PaidCompanionDetailTab = .profile
    @State private var reviewRefreshToken = 0

    private var relatedActivities: [Activity] {
        Array(
            activities.activities(matchingTitles: companion.relatedActivityTitles)
                .prefix(ActivityRelatedRecommender.displayLimit)
        )
    }

    private var serviceSKUs: [BuddyCompanionServiceSKU] {
        BuddyCompanionServiceMenu.skus(for: companion)
    }

    private var reviewStats: PlatformReviewStats {
        PlatformReviewsStore.stats(for: .companion(companion.id))
    }

    var body: some View {
        Form {
            Section {
                BuddyDetailHeroGallery(
                    profile: companion.profile,
                    verifiedBadge: companion.isVerified
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if let line = source.contextLine {
                Section {
                    BuddyDetailSourceRow(line: line, source: source)
                } header: {
                    Text(BuddyMemberCopy.sourceSectionTitle)
                }
            }

            Section {
                BuddyDetailProfileHeader(
                    profile: companion.profile,
                    config: BuddyDetailProfileHeaderFactory.paid(companion: companion),
                    groupAlias: groupAlias,
                    showsFollow: true,
                    isFollowing: app.isFollowing(companion.profile.nickname),
                    onToggleFollow: { app.toggleFollow(companion.profile.nickname) }
                )
            }

            Section {
                Picker("详情分区", selection: $selectedTab) {
                    ForEach(PaidCompanionDetailTab.allCases) { tab in
                        Text(tabTitle(tab)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            switch selectedTab {
            case .service:
                serviceTabSections
            case .profile:
                profileTabSections
            case .reviews:
                PlatformReviewsRatedTab(
                    companion: companion,
                    currentUserName: app.user.name,
                    onChanged: { reviewRefreshToken += 1 }
                )
                .id(reviewRefreshToken)
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbarBackground(.hidden, for: .navigationBar)
        .platformDetailBottomBar {
            BuddyDetailActionBar(
                inviteEnabled: companion.isAvailable,
                inviteTitle: companion.isAvailable
                    ? BuddyDetailCopy.quickBook
                    : BuddyDetailCopy.bookUnavailable,
                greetTitle: greetTitle,
                emphasizeInvite: true,
                onGreet: onGreet,
                onInvite: onQuickBook
            )
        }
    }

    @ViewBuilder
    private var serviceTabSections: some View {
        Section {
            ForEach(serviceSKUs) { sku in
                BuddyCompanionServiceSKURow(
                    sku: sku,
                    bookEnabled: companion.isAvailable,
                    onBook: {
                        if sku.isNegotiable {
                            onGreet()
                        } else if let onBookService {
                            onBookService(sku)
                        } else {
                            onQuickBook()
                        }
                    }
                )
            }
        } header: {
            Text(BuddyDetailCopy.serviceMenuTitle)
        } footer: {
            Text(BuddyDetailCopy.serviceMenuFooter)
        }

        Section {
            BuddyDetailScheduleSection(
                slots: companion.scheduleSlots,
                allowsBooking: companion.isAvailable,
                onSelectBookableDay: { day in
                    if let onBookDay {
                        onBookDay(day)
                    } else {
                        onQuickBook()
                    }
                }
            )
        } header: {
            Text(BuddyDetailCopy.scheduleTitle)
        }

        if !relatedActivities.isEmpty {
            Section {
                DetailRelatedActivitiesRail(activities: relatedActivities)
            } header: {
                Text(BuddyDetailCopy.relatedTitle)
            } footer: {
                Text(BuddyDetailCopy.relatedFooter)
            }
        }
    }

    @ViewBuilder
    private var profileTabSections: some View {
        // 与同好详情一致：身份卡含简介；共同点 → 基本资料 → 服务 → 信任
        if companion.profile.hasVoiceIntro {
            Section {
                BuddyPublicVoiceIntroRow(profile: companion.profile)
            } header: {
                Text(BuddyVoiceIntroCopy.publicSectionTitle)
            }
        }

        let matchSection = BuddyDetailMatchSection(profile: companion.profile)
        Section {
            matchSection
        } header: {
            Text(matchSection.sectionTitle)
        }

        Section {
            BuddyDetailPerformanceSection(companion: companion)
        } header: {
            Text(BuddyDetailCopy.performanceTitle)
        }

        Section {
            BuddyDetailBasicInfoSection(profile: companion.profile)
        } header: {
            Text(BuddyDetailCopy.basicInfoTitle)
        }

        Section {
            BuddyDetailServiceInfoSection(companion: companion)
        } header: {
            Text(BuddyDetailCopy.serviceTitle)
        }

        TrustPublicProfileSections(
            nickname: companion.profile.nickname,
            currentUserName: app.user.name,
            buddyItem: .paid(companion),
            compact: false
        )
    }

    private func tabTitle(_ tab: PaidCompanionDetailTab) -> String {
        switch tab {
        case .service, .profile:
            tab.rawValue
        case .reviews:
            "评价 \(reviewStats.total)"
        }
    }
}
