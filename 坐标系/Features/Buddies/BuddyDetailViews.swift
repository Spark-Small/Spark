//
//  BuddyDetailViews.swift
//  坐标系
//
//  搭子详情：Form 规范对齐活动详情；同好 / 陪玩完整资料展示。
//

import SwiftUI

struct BuddyDetailRouteView: View {
    let item: DiscoverBuddyItem

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(\.dismiss) private var dismiss

    @State private var showReport = false

    var body: some View {
        Group {
            switch item {
            case .free(let buddy):
                CircleBuddyDetailView(
                    buddy: buddy,
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
                    onGreet: {
                        let greeting = "你好！我看到你提供「\(companion.specialty)」，想预约一下。你最近方便吗？"
                        if let convo = app.startDirectChat(with: companion.profile.nickname, greeting: greeting) {
                            app.openMessages(conversationID: convo.id)
                        }
                    },
                    onInvite: { buddies.book(companion) }
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
                        app.blockUser(item.profile.nickname)
                        dismiss()
                    }
                } label: {
                    Label("更多", systemImage: "ellipsis")
                }
            }
        }
        .confirmationDialog("举报 \(item.profile.nickname)", isPresented: $showReport, titleVisibility: .visible) {
            Button("骚扰或不适内容", role: .destructive) {
                submitBuddyReport(reason: "骚扰或不适内容")
            }
            Button("虚假资料", role: .destructive) {
                submitBuddyReport(reason: "虚假资料")
            }
            Button("取消", role: .cancel) {}
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
            BuddyBookingSheet(companion: companion) { scheduledAt, hours, slotLabel in
                _ = buddies.recordBooking(
                    companion: companion,
                    scheduledAt: scheduledAt,
                    hours: hours,
                    slotLabel: slotLabel
                )
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
    var onGreet: () -> Void
    var onInvite: () -> Void

    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
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

            Section {
                BuddyDetailIdentitySection(
                    profile: buddy.profile,
                    pitch: buddy.profile.lookingFor,
                    statusLine: buddy.isOnline ? BuddyDetailCopy.online : buddy.profile.lastActiveText,
                    statusTint: buddy.isOnline ? PlatformStatus.success : .secondary
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

            Section {
                BuddyDetailReviewsSection(reviews: buddy.reviews)
            } header: {
                Text(BuddyDetailCopy.reviewsTitle)
            }

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
            BuddyDetailActionBar(onGreet: onGreet, onInvite: onInvite)
        }
        .communityAuthorSheet($authorDestination)
    }
}

// MARK: - Paid

struct PaidCompanionDetailView: View {
    let companion: PaidCompanion
    var onGreet: () -> Void
    var onInvite: () -> Void

    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
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

            Section {
                BuddyDetailIdentitySection(
                    profile: companion.profile,
                    pitch: companion.specialty,
                    statusLine: companion.priceText,
                    metricsFooter: String(
                        format: "%@ · %@ · %@",
                        BuddyDetailCopy.ratingValue(companion.rating) + " 分",
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
                BuddyDetailScheduleSection(slots: companion.scheduleSlots)
            } header: {
                Text(BuddyDetailCopy.scheduleTitle)
            }

            Section {
                BuddyDetailReviewsSection(reviews: companion.reviews)
            } header: {
                Text(BuddyDetailCopy.reviewsTitle)
            }

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
                onGreet: onGreet,
                onInvite: onInvite
            )
        }
        .communityAuthorSheet($authorDestination)
    }
}
