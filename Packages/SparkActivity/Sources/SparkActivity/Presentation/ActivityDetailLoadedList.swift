// Module: SparkActivity — Loaded activity detail (Meetup-style scroll layout).

import SparkDesignSystem
import SwiftUI

struct ActivityDetailLoadedList: View {
    @Environment(\.openURL) var openURL
    @Bindable var viewModel: ActivityDetailViewModel
    let activity: ActivityDetail
    let inviteCandidates: [ActivityInviteCandidate]
    let isAuthenticated: Bool
    let onSignInRequired: (() -> Void)?
    let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    let onCommunityRecap: ((ActivityDetail) -> Void)?
    let fetchBuddyRecommendation: ((String) async -> (listingID: String, title: String, subtitle: String)?)?
    let onOpenBuddyListing: ((String) -> Void)?
    let onRequestAddToCalendar: () -> Void
    let onReportTapped: (() -> Void)?
    let tabAccessoryBottomInset: CGFloat
    @Binding var meetupMapRoute: ActivityMeetupMapRoute?
    @Binding var showHostAgainCreate: Bool

    @State private var showsAllHostUpcomingEvents = false

    init(
        viewModel: ActivityDetailViewModel,
        activity: ActivityDetail,
        inviteCandidates: [ActivityInviteCandidate],
        isAuthenticated: Bool,
        onSignInRequired: (() -> Void)?,
        onOpenGroupChat: ((ActivityDetail) async -> Void)?,
        onCommunityRecap: ((ActivityDetail) -> Void)?,
        fetchBuddyRecommendation: ((String) async -> (listingID: String, title: String, subtitle: String)?)? = nil,
        onOpenBuddyListing: ((String) -> Void)? = nil,
        onRequestAddToCalendar: @escaping () -> Void,
        onReportTapped: (() -> Void)?,
        tabAccessoryBottomInset: CGFloat,
        meetupMapRoute: Binding<ActivityMeetupMapRoute?>,
        showHostAgainCreate: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self.activity = activity
        self.inviteCandidates = inviteCandidates
        self.isAuthenticated = isAuthenticated
        self.onSignInRequired = onSignInRequired
        self.onOpenGroupChat = onOpenGroupChat
        self.onCommunityRecap = onCommunityRecap
        self.fetchBuddyRecommendation = fetchBuddyRecommendation
        self.onOpenBuddyListing = onOpenBuddyListing
        self.onRequestAddToCalendar = onRequestAddToCalendar
        self.onReportTapped = onReportTapped
        self.tabAccessoryBottomInset = tabAccessoryBottomInset
        _meetupMapRoute = meetupMapRoute
        _showHostAgainCreate = showHostAgainCreate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                meetupCoverSection(activity: activity)
                meetupPrimaryInfoSection(activity: activity)
                meetupDecisionNoticesSection(activity: activity)

                meetupClubSection(activity: activity)
                meetupDescriptionSection(activity: activity)
                meetupGroupChatSection(activity: activity, onOpenGroupChat: onOpenGroupChat)
                ActivityDetailPhotosSection()
                ActivityDetailCommentsSection(
                    isAuthenticated: isAuthenticated,
                    canParticipate: activity.rsvpStatus.hasGroupChatAccess,
                    onSignInRequired: onSignInRequired
                )

                meetupSupplementalSections(activity: activity)
            }
            .padding(
                .bottom,
                SparkLayoutMetrics.sectionVerticalPadding + tabAccessoryBottomInset
            )
        }
        .background(.background)
        .disabled(viewModel.isUpdatingRSVP || viewModel.isPerformingHostAction)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(
                localized: "activity.detail.loaded.a11y",
                defaultValue: "活动详情",
                comment: "Activity detail list"
            )
        )
    }

    @ViewBuilder
    private func meetupSupplementalSections(activity: ActivityDetail) -> some View {
        meetupHostingGoingSection(activity: activity)
        meetupRelatedTopicsSection(activity: activity)
        buddyRecommendationSection(activity: activity)

        if activity.rsvpStatus == .host, !activity.attendees.isEmpty {
            meetupAttendeesSection(activity: activity)
        }

        meetupHostUpcomingCarouselSection(showsAll: $showsAllHostUpcomingEvents)
        meetupHostPastCarouselSection()
        meetupSimilarCarouselSection(activity: activity)

        if showsInviteFriendsSection(for: activity) {
            meetupInviteFriendsSection(activity: activity)
        }

        postEventScrollSection(activity: activity)
        meetupReportFooterSection(activity: activity, onReportTapped: onReportTapped)
        meetupSecondaryNoticesSection()
    }

    @ViewBuilder
    private func buddyRecommendationSection(activity: ActivityDetail) -> some View {
        if let fetchBuddyRecommendation, let onOpenBuddyListing {
            ActivityDetailBuddyRecommendationSection(
                activityCategory: activity.category,
                fetchRecommendation: { category in
                    guard let recommendation = await fetchBuddyRecommendation(category) else { return nil }
                    return ActivityBuddyRecommendation(
                        listingID: recommendation.listingID,
                        title: recommendation.title,
                        subtitle: recommendation.subtitle
                    )
                },
                onOpenListing: onOpenBuddyListing
            )
        }
    }

    @ViewBuilder
    private func meetupAttendeesSection(activity: ActivityDetail) -> some View {
        let isHostView = activity.rsvpStatus == .host
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            meetupDetailSubsectionHeader(
                String(
                    localized: "activity.host.roster.section",
                    defaultValue: "报名名单",
                    comment: "Host roster"
                )
            )

            meetupInsetActionsGroup {
                ForEach(activity.attendees) { attendee in
                    attendeeRow(attendee: attendee, isHostView: isHostView)
                    if attendee.id != activity.attendees.last?.id {
                        meetupActionDivider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func attendeeRow(attendee: ActivityAttendee, isHostView: Bool) -> some View {
        HStack(spacing: 10) {
            Text(String(attendee.displayName.prefix(1)))
                .font(.caption.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.quaternary, in: Circle())

            Text(attendee.displayName)
                .font(.body)
            Spacer(minLength: 0)
            if attendee.isHost {
                Text(
                    String(localized: "activity.attendee.host", defaultValue: "主办", comment: "Host badge")
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            } else if attendee.isVerified {
                Text(
                    String(localized: "activity.attendee.verified", defaultValue: "已实名", comment: "Verified badge")
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            } else if attendee.isCoHost {
                Text(
                    String(localized: "activity.host.cohost.badge", defaultValue: "协办", comment: "Co-host badge")
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            } else if isHostView, let status = attendee.rsvpStatus {
                Text(status.localizedLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if status == .waitlisted {
                    Button(
                        String(
                            localized: "activity.host.promote",
                            defaultValue: "提升",
                            comment: "Promote waitlist"
                        )
                    ) {
                        Task { await viewModel.promoteWaitlistedAttendee(attendee.id) }
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
    }

    @ViewBuilder
    private func meetupInviteFriendsSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            meetupDetailSubsectionHeader(
                String(
                    localized: "activity.inviteFriends.section",
                    defaultValue: "邀请好友",
                    comment: "Invite friends section"
                )
            )
            ActivityInviteFriendsSection(
                activity: activity,
                inviteCandidates: inviteCandidates
            ) {
                viewModel.notifyInviteCopied()
            }
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.blockSpacing)

            if viewModel.shouldPromptInviteFriends {
                Text(
                    String(
                        localized: "activity.inviteFriends.afterRSVP",
                        defaultValue: "已报名！把活动发给好友，约好一起参加。",
                        comment: "Post-RSVP invite hint"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            }
        }
    }
}

#Preview("Loaded — act_1") {
    @Previewable @State var meetupMapRoute: ActivityMeetupMapRoute?
    @Previewable @State var viewModel = ActivityDetailViewModel(
        activityID: "act_1",
        repository: MockActivityFeedRepository()
    )

    if let activity = MockActivityCatalog.detail(id: "act_1") {
        NavigationStack {
            ActivityDetailLoadedList(
                viewModel: viewModel,
                activity: activity,
                inviteCandidates: [],
                isAuthenticated: true,
                onSignInRequired: nil,
                onOpenGroupChat: nil,
                onCommunityRecap: nil,
                onRequestAddToCalendar: {},
                onReportTapped: {},
                tabAccessoryBottomInset: 0,
                meetupMapRoute: $meetupMapRoute,
                showHostAgainCreate: .constant(false)
            )
            .environment(ActivityFavoriteStore())
            .task {
                await viewModel.load()
            }
        }
    }
}

#Preview("Loaded — Dark XL") {
    @Previewable @State var meetupMapRoute: ActivityMeetupMapRoute?
    @Previewable @State var viewModel = ActivityDetailViewModel(
        activityID: "act_1",
        repository: MockActivityFeedRepository()
    )

    if let activity = MockActivityCatalog.detail(id: "act_1") {
        NavigationStack {
            ActivityDetailLoadedList(
                viewModel: viewModel,
                activity: activity,
                inviteCandidates: [],
                isAuthenticated: true,
                onSignInRequired: nil,
                onOpenGroupChat: nil,
                onCommunityRecap: nil,
                onRequestAddToCalendar: {},
                onReportTapped: nil,
                tabAccessoryBottomInset: 72,
                meetupMapRoute: $meetupMapRoute,
                showHostAgainCreate: .constant(false)
            )
            .environment(ActivityFavoriteStore())
            .task {
                await viewModel.load()
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
    }
}
