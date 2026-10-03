//
//  ActivityDetailView+Chrome.swift
//  坐标系
//
//  活动详情顶栏 / 底栏：右上角仅「更多」；已结束无行动时用系统 ContentUnavailableView。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

extension ActivityDetailView {
    // MARK: - Toolbar

    @ToolbarContentBuilder
    func activityDetailToolbar(for activity: Activity) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                moreMenuContent(for: activity)
            } label: {
                Image(systemName: "ellipsis")
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(ActivityDetailCopy.moreMenu)
        }

        if horizontalSizeClass == .regular {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("侧栏", systemImage: "sidebar.trailing") {
                    showDetailInspector.toggle()
                }
                .platformNavigationBarItemChrome()
            }
        }
    }

    @ViewBuilder
    func moreMenuContent(for live: Activity) -> some View {
        Button(ActivityCardStatus.shareActivity, systemImage: "square.and.arrow.up") {
            showShareSheet = true
        }

        Button {
            model.toggleFavorite(live.id)
        } label: {
            Label(
                model.isFavorite(live.id) ? ActivityCardStatus.unfavorite : ActivityCardStatus.favorite,
                systemImage: model.isFavorite(live.id) ? "bookmark.fill" : "bookmark"
            )
        }

        if model.isJoined(live.id) || isHost {
            if canOpenActivityJourney(for: live) {
                activityJourneyNavigationLink(activityID: live.id, slot: "detail-more-journey")
            } else {
                Button(ActivityDetailCopy.credentialReissueAction, systemImage: "ticket") {
                    reissueActivityCredential(for: live)
                }
            }

            Button(ActivityDetailCopy.openGroupChat, systemImage: "bubble.left.and.bubble.right") {
                openGroupChat(for: live)
            }
        }

        Button(ActivityDetailCopy.reportAction, systemImage: "exclamationmark.bubble", role: .destructive) {
            showReportSheet = true
        }

        Divider()

        NavigationLink {
            ProfileFavoriteActivitiesLibraryView()
        } label: {
            Label(ActivityBrowseCopy.favoritesLibrary, systemImage: "bookmark")
        }

        if isHost {
            Divider()

            NavigationLink {
                ActivityHostManageView(activityID: live.id)
            } label: {
                Label(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3")
            }
            Button(ActivityCardStatus.refineContent, systemImage: "square.and.pencil") {
                showContentEditor = true
            }
            Button(ActivityDetailCopy.hostManageEditBasics, systemImage: "pencil") {
                app.beginEditActivity(live.id)
            }
        }
    }

    func canOpenActivityJourney(for activity: Activity) -> Bool {
        passStore.activityPass(for: activity, activeOnly: true) != nil
            || passStore.activityPass(for: activity, activeOnly: false)?.voided == true
    }

    func reissueActivityCredential(for activity: Activity) {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            _ = passStore.issueActivityTicket(order: order, activity: activity)
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: activity)
        }
        ordersRevision += 1
    }

    // MARK: - Bottom bar

    @ViewBuilder
    func bottomBar(_ activity: Activity) -> some View {
        if activity.isLifecycleEnded {
            endedBottomBar(activity)
        } else if isHost {
            hostBottomBar(activity)
        } else {
            participantBottomBar(activity)
        }
    }

    @ViewBuilder
    func endedBottomBar(_ activity: Activity) -> some View {
        if isHost {
            hostBottomBar(activity)
        } else if model.isJoined(activity.id) {
            DetailBottomActionBar {
                activityJourneyNavigationLink(activityID: activity.id, slot: "detail-ended-journey")
                    .activityDetailBottomPrimaryCTA()
            }
        } else {
            // 系统空态 / 状态组件（非自绘通知条）
            ContentUnavailableView(
                ActivityDetailCopy.activityEnded,
                systemImage: "calendar.badge.clock",
                description: Text(ActivityDetailCopy.activityEndedDescription)
            )
            .frame(maxWidth: .infinity)
        }
    }

    func hostBottomBar(_ activity: Activity) -> some View {
        DetailBottomActionBar {
            activityJourneyNavigationLink(activityID: activity.id, slot: "detail-host-journey")
                .activityDetailBottomSecondaryCTA()

            NavigationLink {
                ActivityHostManageView(activityID: activity.id)
            } label: {
                Label(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3")
            }
            .activityDetailBottomPrimaryCTA()
        }
    }

    func participantBottomBar(_ activity: Activity) -> some View {
        DetailBottomActionBar {
            if model.isJoined(activity.id) {
                Button(ActivityDetailCopy.cancelRegistration) {
                    requestCancelRegistration(activity)
                }
                .activityDetailBottomSecondaryCTA()

                activityJourneyNavigationLink(activityID: activity.id, slot: "detail-joined-journey")
                    .activityDetailBottomPrimaryCTA()
            } else {
                joinPrimaryButton(activity)
            }
        }
    }

    @ViewBuilder
    func joinPrimaryButton(_ activity: Activity) -> some View {
        let waitlisted = model.isWaitlisted(activity.id)
        let title = ActivityDetailCopy.joinButtonTitle(
            free: activity.isFree,
            almostFull: activity.isAlmostFull,
            remaining: activity.remainingSpots,
            full: activity.isFull,
            waitlisted: waitlisted,
            hasOpenSpotFromWaitlist: !activity.isFull && waitlisted
        )
        let baseHint = ActivityDetailCopy.joinButtonHint(
            full: activity.isFull,
            waitlisted: waitlisted,
            free: activity.isFree
        )
        let identitySatisfied = IdentityAccessGate.requirement(
            user: app.user,
            auth: app.auth,
            photoVerification: app.photoVerificationStore
        ) == .satisfied
        let hint = identitySatisfied
            ? baseHint
            : ActivityDetailCopy.joinNeedsVerificationHint

        if activity.isFull {
            Button(title) {
                guard app.requireIdentityAccess(source: .activityJoin) else { return }
                _ = model.toggleWaitlist(activity.id)
            }
                .activityDetailBottomPrimaryCTA()
                .accessibilityHint(hint)
        } else if showsWaitlistPromotion(for: activity) {
            Button(title) { presentJoinConfirm(for: activity, waitlistPromotion: true) }
                .activityDetailBottomPrimaryCTA()
                .accessibilityHint(hint)
        } else if activity.isFree {
            Button(title) { presentJoinConfirm(for: activity, waitlistPromotion: false) }
                .activityDetailBottomPrimaryCTA()
                .accessibilityHint(hint)
        } else {
            Button { presentJoinConfirm(for: activity, waitlistPromotion: false) } label: {
                Label(title, systemImage: "bolt.fill")
            }
            .activityDetailBottomPrimaryCTA()
            .accessibilityHint(hint)
        }
    }

    func showsWaitlistPromotion(for activity: Activity) -> Bool {
        model.isWaitlisted(activity.id)
            && !activity.isFull
            && !activity.isLifecycleEnded
    }

    func presentJoinConfirm(for activity: Activity, waitlistPromotion: Bool) {
        guard app.requireIdentityAccess(source: .activityJoin) else { return }
        joinConfirmWaitlistPromotion = waitlistPromotion
        showJoinConfirm = true
    }
}
