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
                    profile: companion.profile,
                    config: BuddyDetailProfileHeaderFactory.paid(companion: companion),
                    groupAlias: groupAlias,
                    showsFollow: true,
                    isFollowing: app.isFollowing(companion.profile.nickname),
                    onToggleFollow: { app.toggleFollow(companion.profile.nickname) }
                )
            }

            Section {
                Picker(BuddyBrowseCopy.PaidShelf.detailTabPicker, selection: $selectedTab) {
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

        CommunityAuthorRecentPostsSection(
            authorName: companion.profile.nickname,
            sectionTitle: BuddyDetailCopy.communityPostsTitle
        )
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
            tab.title
        case .reviews:
            BuddyBrowseCopy.PaidShelf.tabReviewsCount(reviewStats.total)
        }
    }
}
