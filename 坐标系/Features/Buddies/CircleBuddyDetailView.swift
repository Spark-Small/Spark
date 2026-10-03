//
//  CircleBuddyDetailView.swift
//  坐标系
//
//  同好搭子详情。
//

import SwiftUI
import CoordinateModels

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

            CommunityAuthorRecentPostsSection(
                authorName: buddy.profile.nickname,
                sectionTitle: BuddyDetailCopy.communityPostsTitle
            )
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

