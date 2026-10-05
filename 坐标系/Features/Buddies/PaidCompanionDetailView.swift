//
//  PaidCompanionDetailView.swift
//  坐标系
//
//  付费陪玩详情。
//

import SwiftUI
import CoordinateModels

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

    private var isSelfViewer: Bool {
        companion.profile.nickname.caseInsensitiveCompare(app.user.name) == .orderedSame
    }

    private var displayProfile: BuddyProfile {
        isSelfViewer
            ? PublicProfileProjection.buddyProfile(companion.profile, from: app.user)
            : companion.profile
    }

    private var paidHeaderConfig: BuddyDetailProfileHeaderConfig {
        var config = BuddyDetailProfileHeaderFactory.paid(companion: companion)
        config.showsGenderAge = isSelfViewer ? app.user.hasGenderAgeBadge : true
        return config
    }

    var body: some View {
        Form {
            Section {
                BuddyDetailHeroGallery(
                    profile: displayProfile,
                    verifiedBadge: companion.isVerified
                )
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
                    config: paidHeaderConfig,
                    groupAlias: groupAlias,
                    showsFollow: !isSelfViewer,
                    isFollowing: app.isFollowing(companion.profile.nickname),
                    onToggleFollow: { app.toggleFollow(companion.profile.nickname) }
                )
            }

            // 官方分段：系统 Picker + .segmented（经 platformSegmentedPickerChrome；iOS 26 自动玻璃）。
            Section {
                Picker(BuddyBrowseCopy.PaidShelf.detailTabPicker, selection: $selectedTab) {
                    ForEach(PaidCompanionDetailTab.allCases) { tab in
                        Text(tabTitle(tab)).tag(tab)
                    }
                }
                .platformSegmentedPickerChrome()
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
                    onChanged: {}
                )
            case .posts:
                postsTabSections
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

        if !isSelfViewer {
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
        }

        relatedActivitiesSection
    }

    @ViewBuilder
    private var postsTabSections: some View {
        CommunityAuthorRecentPostsSection(
            authorName: companion.profile.nickname,
            sectionTitle: BuddyDetailCopy.communityPostsTitle,
            showsEmptyState: true,
            emptyTitle: BuddyDetailCopy.postsEmptyTitle,
            emptyDescription: BuddyDetailCopy.postsEmptyDescription
        )
    }

    @ViewBuilder
    private var profileTabSections: some View {
        BuddyDetailAboutSection(profile: displayProfile)

        if displayProfile.hasVoiceIntro {
            Section {
                BuddyPublicVoiceIntroRow(profile: displayProfile)
            } header: {
                Text(BuddyVoiceIntroCopy.publicSectionTitle)
            }
        }

        Section {
            BuddyDetailPerformanceSection(companion: companion)
        } header: {
            Text(BuddyDetailCopy.performanceTitle)
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

        relatedActivitiesSection
    }

    @ViewBuilder
    private var relatedActivitiesSection: some View {
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

    private func tabTitle(_ tab: PaidCompanionDetailTab) -> String {
        switch tab {
        case .service, .profile, .posts:
            tab.title
        case .reviews:
            BuddyBrowseCopy.PaidShelf.tabReviewsCount(reviewStats.total)
        }
    }
}
