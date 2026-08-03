//
//  BuddyDetailViews.swift
//  坐标系
//
//  搭子详情：Form 规范对齐活动详情；同好 / 陪玩完整资料展示。
//

import SwiftUI

struct BuddyDetailRouteView: View {
    let item: DiscoverBuddyItem
    var source: BuddyProfileSource = .discover

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(\.dismiss) private var dismiss

    @State private var showReport = false
    @State private var confirmBlock = false

    var body: some View {
        Group {
            switch item {
            case .free(let buddy):
                CircleBuddyDetailView(
                    buddy: buddy,
                    source: source,
                    onGreet: {
                        let greeting = "你好！我想约你一起「\(buddy.profile.lookingFor)」——你最近有空吗？"
                        if let convo = app.startDirectChat(with: buddy.profile.nickname, greeting: greeting) {
                            app.openMessages(conversationID: convo.id)
                        }
                    },
                    onInvite: { buddies.invite(buddy.profile.nickname) }
                )
            case .paid(let companion):
                PaidCompanionDetailView(
                    companion: companion,
                    source: source,
                    onGreet: {
                        let greeting = "你好！我看到你提供「\(companion.specialty)」，想预约一下。你最近方便吗？"
                        if let convo = app.startDirectChat(with: companion.profile.nickname, greeting: greeting) {
                            app.openMessages(conversationID: convo.id)
                        }
                    },
                    onInvite: { buddies.book(companion) },
                    onBookDay: { day in
                        buddies.book(companion, initialDay: day)
                    }
                )
            }
        }
        .platformSecondaryPage()
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
        .sheet(item: Binding(
            get: { buddies.inviteTarget },
            set: { buddies.inviteTarget = $0 }
        )) { target in
            BuddyInviteSheet(nickname: target.nickname, activities: activities.inviteableActivities) { activity in
                buddies.recordInvite(nickname: target.nickname, activity: activity)
            }
        }
        .sheet(item: Binding(
            get: { buddies.bookingTarget },
            set: { buddies.bookingTarget = $0 }
        )) { companion in
            BuddyBookingSheet(
                companion: companion,
                initialDay: buddies.bookingInitialDay
            ) { scheduledAt, hours, slotLabel in
                _ = buddies.recordBooking(
                    companion: companion,
                    scheduledAt: scheduledAt,
                    hours: hours,
                    slotLabel: slotLabel
                )
            }
            .onDisappear {
                if buddies.bookingTarget == nil {
                    buddies.bookingInitialDay = nil
                }
            }
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
    var onGreet: () -> Void
    var onInvite: () -> Void

    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @State private var authorDestination: CommunityAuthorDestination?

    private var relatedActivities: [Activity] {
        buddy.relatedActivityTitles.compactMap { activities.activity(matchingTitle: $0) }
    }

    var body: some View {
        let matchSection = BuddyDetailMatchSection(profile: buddy.profile)

        Form {
            Section {
                BuddyDetailHeroGallery(profile: buddy.profile)
                    .listRowInsets(EdgeInsets())
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
                BuddyDetailIdentitySection(
                    profile: buddy.profile,
                    pitch: buddy.profile.lookingFor,
                    statusLine: identityStatusLine(
                        isOnline: buddy.isOnline,
                        lastActive: buddy.profile.lastActiveText
                    ),
                    statusTint: buddy.isOnline && PrivacyPreferences.showOnline
                        ? PlatformStatus.success
                        : .secondary
                )
            }

            Section {
                BuddyDetailTrustRow(
                    trust: .make(free: buddy),
                    onProfile: {
                        authorDestination = buddies.authorDestination(for: buddy.profile.nickname)
                    },
                    onChat: onGreet
                )
            } header: {
                Text(BuddyDetailCopy.trustTitle)
            }

            Section {
                BuddyDetailBasicInfoSection(profile: buddy.profile)
            } header: {
                Text(BuddyDetailCopy.basicInfoTitle)
            }

            Section {
                matchSection
            } header: {
                Text(matchSection.sectionTitle)
            }

            Section {
                Text(buddy.profile.bio)
                    .font(.body)
                    .foregroundStyle(.primary)
            } header: {
                Text(BuddyDetailCopy.aboutTitle)
            }

            Section {
                BuddyDetailCircleRow(circleName: buddy.circleName, topic: buddy.topic)
            } header: {
                Text(BuddyDetailCopy.circleTitle)
            }

            Section {
                BuddyDetailScheduleSection(slots: buddy.scheduleSlots)
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
                    BuddyDetailRelatedRail(activities: relatedActivities)
                } header: {
                    Text(BuddyDetailCopy.relatedTitle)
                }
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(buddy.profile.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BuddyDetailActionBar(
                inviteEnabled: true,
                inviteTitle: BuddyDetailCopy.invite,
                onGreet: onGreet,
                onInvite: onInvite
            )
        }
        .communityAuthorSheet($authorDestination)
    }
}

// MARK: - Paid

struct PaidCompanionDetailView: View {
    let companion: PaidCompanion
    var source: BuddyProfileSource = .discover
    var onGreet: () -> Void
    var onInvite: () -> Void
    var onBookDay: ((Date) -> Void)? = nil

    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @State private var authorDestination: CommunityAuthorDestination?

    private var relatedActivities: [Activity] {
        companion.relatedActivityTitles.compactMap { activities.activity(matchingTitle: $0) }
    }

    var body: some View {
        let matchSection = BuddyDetailMatchSection(profile: companion.profile)

        Form {
            Section {
                BuddyDetailHeroGallery(
                    profile: companion.profile,
                    verifiedBadge: companion.isVerified
                )
                .listRowInsets(EdgeInsets())
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
                BuddyDetailIdentitySection(
                    profile: companion.profile,
                    pitch: companion.specialty,
                    statusLine: companion.priceText,
                    metricsFooter: String(
                        format: "%@ · %@",
                        BuddyDetailCopy.ordersValue(companion.orderCount),
                        companion.responseTime
                    ),
                    statusTint: PlatformStatus.warning
                )
            }

            Section {
                BuddyDetailTrustRow(
                    trust: .make(paid: companion),
                    onProfile: {
                        authorDestination = buddies.authorDestination(for: companion.profile.nickname)
                    },
                    onChat: onGreet
                )
            } header: {
                Text(BuddyDetailCopy.trustTitle)
            }

            Section {
                BuddyDetailBasicInfoSection(profile: companion.profile)
            } header: {
                Text(BuddyDetailCopy.basicInfoTitle)
            }

            Section {
                BuddyDetailServiceInfoSection(companion: companion)
                Text(companion.profile.bio)
                    .font(.body)
                    .foregroundStyle(.primary)
            } header: {
                Text(BuddyDetailCopy.serviceTitle)
            }

            Section {
                matchSection
            } header: {
                Text(matchSection.sectionTitle)
            }

            Section {
                BuddyDetailScheduleSection(
                    slots: companion.scheduleSlots,
                    allowsBooking: companion.isAvailable,
                    onSelectBookableDay: { day in
                        if let onBookDay {
                            onBookDay(day)
                        } else {
                            onInvite()
                        }
                    }
                )
            } header: {
                Text(BuddyDetailCopy.scheduleTitle)
            }

            TrustPublicProfileSections(
                nickname: companion.profile.nickname,
                currentUserName: app.user.name,
                buddyItem: .paid(companion),
                compact: false
            )

            if !relatedActivities.isEmpty {
                Section {
                    BuddyDetailRelatedRail(activities: relatedActivities)
                } header: {
                    Text(BuddyDetailCopy.relatedTitle)
                }
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(companion.profile.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BuddyDetailActionBar(
                inviteEnabled: companion.isAvailable,
                inviteTitle: companion.isAvailable ? BuddyDetailCopy.book : BuddyDetailCopy.bookUnavailable,
                emphasizeInvite: source.emphasizesBooking,
                onGreet: onGreet,
                onInvite: onInvite
            )
        }
        .communityAuthorSheet($authorDestination)
    }
}

private func identityStatusLine(isOnline: Bool, lastActive: String) -> String {
    if let line = PrivacyPreferences.statusLine(isOnline: isOnline, lastActiveText: lastActive) {
        return line
    }
    if isOnline, !PrivacyPreferences.showOnline {
        return lastActive.isEmpty ? "近期活跃" : lastActive
    }
    return lastActive
}
