//
//  ActivityDetailContent.swift
//  坐标系
//
//  活动详情页内容区：Form 分区、Hero、底栏（与 ActivityDetailView 共享状态）。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

extension ActivityDetailView {
    // MARK: - Content

    func detailContent(_ live: Activity) -> some View {
        let blueprint = ActivityDetailBlueprint.make(for: live)

        return Form {
            Section {
                hero(live)
                    .id(contentRevision)
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 0,
                        trailing: 0
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            detailFormSections(live, blueprint: blueprint)
        }
        // 分区间距 / 顶边距交给系统语义，不叠自定义 pt
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle(live.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: live.id) {
            guard !revealsSecondaryContent else { return }
            await Task.yield()
            try? await Task.sleep(for: ActivityZoomEngagement.postTransitionDelay)
            guard !Task.isCancelled else { return }
            revealsSecondaryContent = true
        }
        .toolbar {
            activityDetailToolbar(for: live)
        }
        // Form 头图落在系统顶栏下方；边缘过渡交给 scrollEdgeEffect
        .toolbarBackground(.hidden, for: .navigationBar)
        .inspector(isPresented: $showDetailInspector) {
            ActivityDetailSideInspector(
                activity: live,
                related: ActivityRelatedRecommender.related(to: live, from: model.activities),
                onOpenPeople: { showPeopleSheet = true }
            )
        }
        .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
        .onAppear {
            if horizontalSizeClass == .regular {
                showDetailInspector = true
            }
        }
        .onChange(of: horizontalSizeClass) { _, sizeClass in
            showDetailInspector = sizeClass == .regular
        }
        .onChange(of: model.joinedIDs) { _, _ in
            contentRevision += 1
        }
        .onChange(of: model.isWaitlisted(live.id)) { _, _ in
            contentRevision += 1
        }
        .peerContactDestination(route: $activityContactRoute)
        .sheet(isPresented: $showPeopleSheet) {
            ActivityDetailPeopleSheet(activity: live)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showJoinConfirm) {
            ActivityJoinConfirmSheet(
                activity: live,
                conflicts: model.scheduleConflicts(with: live),
                promotionMode: joinConfirmWaitlistPromotion ? .waitlist : .standard
            ) { note in
                completeJoin(for: live, note: note)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .onChange(of: showJoinConfirm) { _, isPresented in
            if !isPresented {
                joinConfirmWaitlistPromotion = false
            }
        }
        .sheet(isPresented: $showContentEditor) {
            ActivityDetailContentEditorSheet(activity: live) {
                contentRevision += 1
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showOrders) {
            ActivityOrdersSheet(activityID: live.id) {
                ordersRevision += 1
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert(
            ActivityDetailCopy.cancelWithRefundTitle,
            isPresented: Binding(
                get: { cancelRefundActivityID != nil },
                set: { if !$0 { cancelRefundActivityID = nil } }
            )
        ) {
            Button("暂不取消", role: .cancel) {
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelOnly) {
                if let id = cancelRefundActivityID,
                   app.cancelActivityRegistration(id, refundIfPaid: false) {
                    cancelFeedbackMessage = ActivityFeedbackCopy.unjoined
                }
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelWithRefundConfirm, role: .destructive) {
                if let id = cancelRefundActivityID,
                   let order = ActivityPaymentStore.paidOrder(for: id) {
                    cancelAndRefundOrder = order
                }
                cancelRefundActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelWithRefundMessage)
        }
        .alert(
            ActivityDetailCopy.cancelUnpaidTitle,
            isPresented: Binding(
                get: { cancelUnpaidActivityID != nil },
                set: { if !$0 { cancelUnpaidActivityID = nil } }
            )
        ) {
            Button(ActivityDetailCopy.cancelUnpaidKeep, role: .cancel) {
                cancelUnpaidActivityID = nil
            }
            Button(ActivityDetailCopy.cancelUnpaidConfirm, role: .destructive) {
                if let id = cancelUnpaidActivityID,
                   app.cancelActivityRegistration(id) {
                    cancelFeedbackMessage = ActivityFeedbackCopy.unjoined
                }
                cancelUnpaidActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelUnpaidMessage)
        }
        .sheet(item: $cancelAndRefundOrder) { order in
            let activity = model.activity(id: order.activityID)
            let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
            RefundRequestSheet.activityOrder(order, activity: activity, refundNotes: notes) { reason, detail, _ in
                submitCancelAndRefund(order: order, reason: reason, detail: detail)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: Binding(
            get: { presentedRefundRequestID != nil },
            set: { if !$0 { presentedRefundRequestID = nil } }
        )) {
            if let requestID = presentedRefundRequestID {
                RefundStatusSheet(requestID: requestID)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .platformDetailBottomBar {
            bottomBar(live)
        }
        .sheet(isPresented: $showCommentsSheet) {
            ActivityCommentsSheet(
                activityID: live.id,
                hostName: live.hostName,
                currentUserName: model.currentUserName,
                onChanged: {
                    commentsRevision += 1
                }
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    @ViewBuilder
    func detailFormSections(_ live: Activity, blueprint: ActivityDetailBlueprint) -> some View {
        let joined = model.isJoined(live.id)
        let trust = ActivityHostTrust.make(
            hostName: live.hostName,
            liveHostedCount: model.hostedCount(for: live.hostName)
        )
        let paidOrder = ActivityPaymentStore.displayOrder(for: live.id)

        // 标题 + 决策同一 Section：系统行距，避免两张白卡之间再叠一段分区间距
        Section {
            titleBlock(live)

            ActivityDetailDecisionCard(
                activity: live,
                viewerWaitlisted: model.isWaitlisted(live.id),
                canAddCalendarReminder: joined || model.isHost(live),
                hostNote: blueprint.hostNote,
                matchedFriends: ActivityRecommender.matchedFriends(for: live),
                experienceFeedbackTags: live.isLifecycleEnded
                    ? model.feedbackTagSummary(for: live.id)
                    : [],
                onPeople: { showPeopleSheet = true }
            )
        }
        .id(contentRevision)

        if showsWaitlistPromotion(for: live) {
            Section {
                ActivityWaitlistPromotionBanner(activity: live) {
                    presentJoinConfirm(for: live, waitlistPromotion: true)
                }
            } header: {
                Label(ActivityDetailCopy.waitlistPromotionTitle, systemImage: "sparkles")
                    .platformContentSymbolStyle()
            }
        }

        Section {
            ActivityDetailHostTrustRow(
                trust: trust,
                onHost: { showHostProfile = true },
                onChat: { askHost(about: live) }
            )
        } header: {
            Text(ActivityDetailCopy.peopleHostRole)
        }

        ForEach(blueprint.sections) { section in
            Section {
                ActivityDetailCollapsibleSection(
                    title: section.title,
                    summary: ActivityDetailBlueprint.sectionSummary(
                        for: section.id,
                        activity: live,
                        blueprint: blueprint
                    ),
                    isExpanded: expandedBinding(for: section.id)
                ) {
                    sectionBlock(section: section, blueprint: blueprint)
                        .id(section.id)
                }
            }
        }

        if isHost, !live.isLifecycleEnded {
            Section {
                ActivityDetailHostManageCard(activity: live)
            } header: {
                Text(ActivityDetailCopy.hostManageTitle)
            }
        }

        footerActions(live, joined: joined)

        if let paidOrder, joined || isHost {
            Section {
                ActivityDetailOrderBanner(order: paidOrder) { showOrders = true }
            }
            .id(ordersRevision)
        }

        if revealsSecondaryContent {
            ActivityDetailCommentsPreviewSection(
                activityID: live.id,
                hostName: live.hostName,
                onOpenComments: { showCommentsSheet = true }
            )
            .id(commentsRevision)

            if let circle = buddies.relatedCircle(for: live) {
                Section {
                    ActivityDetailRelatedCircleRow(circle: circle)
                } header: {
                    Text(ActivityDetailCopy.relatedCircleTitle)
                }
            }

            let related = ActivityRelatedRecommender.related(to: live, from: model.activities)
            if !related.isEmpty {
                Section {
                    DetailRelatedActivitiesRail(activities: related)
                } header: {
                    Text(ActivityDetailCopy.relatedTitle)
                }
            }
        }
    }

    func expandedBinding(for sectionID: ActivityDetailSectionID) -> Binding<Bool> {
        Binding(
            get: { expandedDetailSections.contains(sectionID) },
            set: { isExpanded in
                if isExpanded {
                    expandedDetailSections.insert(sectionID)
                } else {
                    expandedDetailSections.remove(sectionID)
                }
            }
        )
    }

    @ViewBuilder
    func footerActions(_ live: Activity, joined: Bool) -> some View {
        let showHostEdit = isHost
        let showRecap = joined && live.isLifecycleEnded
        let progress = model.participationRecord(for: live.id)
        let showFeedback = showRecap
            && progress?.feedbackSubmitted != true
            && progress?.feedbackSkipped != true
        if showHostEdit || showRecap || showFeedback {
            Section {
                if showHostEdit {
                    Button {
                        showContentEditor = true
                    } label: {
                        Label(ActivityCardStatus.refineContent, systemImage: "square.and.pencil")
                    }
                }

                if showFeedback {
                    Button {
                        showFeedbackSheet = true
                    } label: {
                        Label(ActivityJourneyCopy.shareFeedback, systemImage: "hand.thumbsup")
                    }
                }

                if showRecap {
                    let recapDone = progress?.recapPublished == true || progress?.recapSkipped == true
                    if !recapDone {
                        Button {
                            openRecapCompose(for: live)
                        } label: {
                            Label(ActivityDetailCopy.recapCTA, systemImage: "square.and.pencil")
                        }
                        Button(ActivityExperienceFeedbackCopy.skip, role: .cancel) {
                            model.skipActivityRecap(live.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Hero / chrome

    func hero(_ activity: Activity) -> some View {
        let weather = LocalPlaceholderWeatherProvider.forecast(for: activity)
        let dateLine =
            "\(Formatters.monthDay.string(from: activity.date)) \(Formatters.weekday.string(from: activity.date))"
        let weatherLine = "\(weather.temperatureC)° · \(weather.conditionText)"
        let chipTitle = "\(dateLine) · \(weatherLine)"

        return DetailHeroChrome {
            ActivityDetailHeroGallery(
                activity: activity,
                onEditGallery: isHost ? { showContentEditor = true } : nil
            )
        } chip: { onMedia in
            DetailHeroInfoChip(
                title: chipTitle,
                systemImage: weather.systemImage,
                onMedia: onMedia
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    func activityDetailToolbar(for activity: Activity) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                favoriteFeedbackPulse += 1
                PlatformMotion.withAnimation(.snappy) {
                    model.toggleFavorite(activity.id)
                }
            } label: {
                Image(systemName: model.isFavorite(activity.id) ? "bookmark.fill" : "bookmark")
                    .symbolEffect(.bounce, value: favoriteFeedbackPulse)
            }
            .platformStateFeedback($favoriteFeedbackPulse)
            .accessibilityLabel(
                model.isFavorite(activity.id)
                    ? ActivityCardStatus.unfavorite
                    : ActivityCardStatus.favorite
            )

            Menu {
                moreMenuContent(for: activity)
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("更多")
        }
        if horizontalSizeClass == .regular {
            ToolbarItem(placement: .primaryAction) {
                Button("侧栏", systemImage: "sidebar.trailing") {
                    showDetailInspector.toggle()
                }
            }
        }
    }

    @ViewBuilder
    func moreMenuContent(for live: Activity) -> some View {
        Button(ActivityCardStatus.shareActivity, systemImage: "square.and.arrow.up") {
            showShareSheet = true
        }

        if model.isJoined(live.id) || isHost {
            if canOpenActivityJourney(for: live) {
                NavigationLink {
                    ActivityCredentialExpandedView(activityID: live.id)
                } label: {
                    Label(ActivityDetailCopy.credentialViewAction, systemImage: "ticket.fill")
                }
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

    func titleBlock(_ activity: Activity) -> some View {
        VStack(alignment: .leading) {
            Text(activity.title)
                .font(.title2.weight(.bold))

            Text(Formatters.activityPitch(from: activity.summary))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    func sectionBlock(
        section: ActivityDetailSection,
        blueprint: ActivityDetailBlueprint
    ) -> some View {
        switch section.id {
        case .plan:
            ActivityDetailTimelineCard(items: blueprint.timeline)
        case .fee:
            ActivityDetailFeeCard(
                included: blueprint.feeIncluded,
                excluded: blueprint.feeExcluded,
                refundNotes: blueprint.refundNotes
            )
        case .prep:
            prepBlock(blueprint)
        case .notes:
            ActivityDetailNumberedNotes(notes: blueprint.registrationNotes)
        }
    }

    @ViewBuilder
    func prepBlock(_ blueprint: ActivityDetailBlueprint) -> some View {
        VStack(alignment: .leading) {
            if !blueprint.gear.isEmpty {
                ActivityDetailGearGrid(items: blueprint.gear)
            }
            if !blueprint.gear.isEmpty, !blueprint.prepNotes.isEmpty {
                Divider()
            }
            if !blueprint.prepNotes.isEmpty {
                ActivityDetailNumberedNotes(notes: blueprint.prepNotes)
            }
        }
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
        } else {
            DetailBottomActionBar {
                if model.isJoined(activity.id) {
                    NavigationLink {
                        ActivityCredentialExpandedView(activityID: activity.id)
                    } label: {
                        Label(ActivityDetailCopy.credentialViewAction, systemImage: "ticket.fill")
                    }
                    .activityDetailBottomPrimaryCTA()
                } else {
                    Label(ActivityDetailCopy.activityEnded, systemImage: "calendar.badge.clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    func hostBottomBar(_ activity: Activity) -> some View {
        DetailBottomActionBar {
            NavigationLink {
                ActivityHostManageView(activityID: activity.id)
            } label: {
                Label(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3")
            }
            .activityDetailBottomSecondaryCTA()

            NavigationLink {
                ActivityCredentialExpandedView(activityID: activity.id)
            } label: {
                Label(ActivityDetailCopy.credentialViewAction, systemImage: "ticket.fill")
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

                NavigationLink {
                    ActivityCredentialExpandedView(activityID: activity.id)
                } label: {
                    Label(ActivityDetailCopy.credentialViewAction, systemImage: "ticket.fill")
                }
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

        if activity.isFull {
            Button(title) { _ = model.toggleWaitlist(activity.id) }
                .activityDetailBottomPrimaryCTA()
        } else if showsWaitlistPromotion(for: activity) {
            Button(title) { presentJoinConfirm(for: activity, waitlistPromotion: true) }
                .activityDetailBottomPrimaryCTA()
        } else if activity.isFree {
            Button(title) { presentJoinConfirm(for: activity, waitlistPromotion: false) }
                .activityDetailBottomPrimaryCTA()
        } else {
            Button { presentJoinConfirm(for: activity, waitlistPromotion: false) } label: {
                Label(title, systemImage: "bolt.fill")
            }
            .activityDetailBottomPrimaryCTA()
        }
    }

    func showsWaitlistPromotion(for activity: Activity) -> Bool {
        model.isWaitlisted(activity.id)
            && !activity.isFull
            && !activity.isLifecycleEnded
    }

    func presentJoinConfirm(for activity: Activity, waitlistPromotion: Bool) {
        joinConfirmWaitlistPromotion = waitlistPromotion
        showJoinConfirm = true
    }
}
