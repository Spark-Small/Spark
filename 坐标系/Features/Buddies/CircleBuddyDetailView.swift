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
    @State private var pendingInviteDay: Date?

    private var relatedActivities: [Activity] {
        Array(
            activities.activities(matchingTitles: buddy.relatedActivityTitles)
                .prefix(ActivityRelatedRecommender.displayLimit)
        )
    }

    private var isSelfViewer: Bool {
        buddy.profile.nickname.caseInsensitiveCompare(app.user.name) == .orderedSame
    }

    private var displayProfile: BuddyProfile {
        isSelfViewer
            ? PublicProfileProjection.buddyProfile(buddy.profile, from: app.user)
            : buddy.profile
    }

    private var freeHeaderConfig: BuddyDetailProfileHeaderConfig {
        var config = BuddyDetailProfileHeaderFactory.free(buddy: buddy)
        config.showsGenderAge = isSelfViewer ? app.user.hasGenderAgeBadge : true
        return config
    }

    var body: some View {
        Form {
            // Meetup 式：封面 → 身份 → 推荐理由 → 基本资料 → 圈子/档期 → 信任档案
            Section {
                BuddyDetailHeroGallery(profile: displayProfile)
                    .platformFullBleedMediaFormRow()
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
                    profile: displayProfile,
                    config: freeHeaderConfig,
                    groupAlias: groupAlias,
                    showsFollow: !isSelfViewer,
                    isFollowing: app.isFollowing(buddy.profile.nickname),
                    onToggleFollow: { app.toggleFollow(buddy.profile.nickname) }
                )
            }

            BuddyDetailAboutSection(profile: displayProfile)

            if displayProfile.hasVoiceIntro {
                Section {
                    BuddyPublicVoiceIntroRow(profile: displayProfile)
                } header: {
                    Text(BuddyVoiceIntroCopy.publicSectionTitle)
                }
            }

            Section {
                BuddyDetailBasicInfoSection(
                    profile: displayProfile,
                    showsDemographics: isSelfViewer ? app.user.hasPublicDemographics : true,
                    omitUnsetDemographics: isSelfViewer,
                    recordedGender: isSelfViewer
                        ? PublicProfileProjection.buddyGender(from: app.user.gender)
                        : nil,
                    cityOverride: isSelfViewer ? app.user.city : nil
                )
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

            if !isSelfViewer {
                Section {
                    BuddyDetailScheduleSection(
                        slots: buddy.scheduleSlots,
                        allowsBooking: !buddy.scheduleSlots.isEmpty,
                        scheduleHint: BuddyBookingFlowCopy.freeScheduleHint,
                        onSelectBookableDay: { day in pendingInviteDay = day }
                    )
                } header: {
                    Text(BuddyDetailCopy.scheduleTitle)
                }
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
        .confirmationDialog(
            BuddyDetailCopy.scheduleInviteConfirmTitle,
            isPresented: Binding(
                get: { pendingInviteDay != nil },
                set: { if !$0 { pendingInviteDay = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(BuddyDetailCopy.scheduleInviteConfirmAction) {
                pendingInviteDay = nil
                onInvite()
            }
            Button(BuddyDetailCopy.cancel, role: .cancel) {
                pendingInviteDay = nil
            }
        } message: {
            Text(BuddyDetailCopy.scheduleInviteConfirmMessage)
        }
    }
}

