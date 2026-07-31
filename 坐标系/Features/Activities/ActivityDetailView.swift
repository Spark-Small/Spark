//
//  ActivityDetailView.swift
//  坐标系
//

import SwiftUI

/// 活动详情：导向「参加」
struct ActivityDetailView: View {
    let activityID: Activity.ID

    @Environment(ActivitiesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(WalletPassStore.self) private var passStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showHostProfile = false
    @State private var showPeopleSheet = false
    @State private var showJoinConfirm = false
    @State private var showPaymentSheet = false
    @State private var showContentEditor = false
    @State private var showOrders = false
    @State private var showShareSheet = false
    @State private var showReportSheet = false
    @State private var profileMemberName: String?
    @State private var contentRevision = 0
    @State private var commentsRevision = 0
    @State private var ordersRevision = 0
    @State private var pendingJoinNote: String?
    @State private var reportMessage: String?
    @State private var joinIssueMessage: String?
    @State private var cancelRefundActivityID: Activity.ID?
    /// 评论 / 相关轨等次要内容：转场首帧后再挂，减轻 Zoom 合成负载
    @State private var revealsSecondaryContent = false

    init(activityID: Activity.ID) {
        self.activityID = activityID
    }

    init(activity: Activity) {
        self.activityID = activity.id
    }

    private var activity: Activity? { model.activity(id: activityID) }
    private var isHost: Bool { activity.map(model.isHost) ?? false }

    var body: some View {
        Group {
            if let live = activity {
                detailContent(live)
            } else {
                ContentUnavailableView(ActivityDetailCopy.missingActivity, systemImage: "calendar")
                    .onAppear(perform: dismiss.callAsFunction)
            }
        }
        .sheet(isPresented: joinSuccessPresented) { joinSuccessSheet }
        .sheet(isPresented: publishSuccessPresented) { publishSuccessSheet }
        .sheet(isPresented: $showShareSheet) {
            if let activity {
                PlatformShareSheet(items: [shareText(for: activity)])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let activity {
                ActivityReportSheet(activity: activity, onSubmit: submitReport)
            }
        }
        .sheet(isPresented: $showHostProfile) {
            if let name = activity?.hostName {
                CommunityAuthorFallbackSheet(name: name)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { profileMemberName != nil },
                set: { if !$0 { profileMemberName = nil } }
            )
        ) {
            if let name = profileMemberName {
                CommunityAuthorFallbackSheet(name: name)
            }
        }
        .alert(
            ActivityDetailCopy.reportReceivedTitle,
            isPresented: Binding(
                get: { reportMessage != nil },
                set: { if !$0 { reportMessage = nil } }
            )
        ) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(reportMessage ?? "")
        }
        .alert(
            ActivityDetailCopy.joinFailedFullAfterPayTitle,
            isPresented: Binding(
                get: { joinIssueMessage != nil },
                set: { if !$0 { joinIssueMessage = nil } }
            )
        ) {
            Button(ActivityCardStatus.joinWaitlist) {
                _ = model.toggleWaitlist(activityID)
                joinIssueMessage = nil
            }
            Button("好的", role: .cancel) {
                joinIssueMessage = nil
            }
        } message: {
            Text(joinIssueMessage ?? "")
        }
    }

    // MARK: - Content

    private func detailContent(_ live: Activity) -> some View {
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
        .task(id: live.id) {
            guard !revealsSecondaryContent else { return }
            await Task.yield()
            try? await Task.sleep(for: ActivityZoomEngagement.postTransitionDelay)
            guard !Task.isCancelled else { return }
            revealsSecondaryContent = true
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ActivityDetailControls.GlassIconMenu(accessibilityLabel: "分享与更多") {
                    moreMenuContent(for: live)
                }
            }
        }
        // Form 头图落在系统顶栏下方；边缘过渡交给 scrollEdgeEffect
        .toolbarBackground(.hidden, for: .navigationBar)
        .platformSecondaryPage()
        .circleDetailNavigationDestination()
        .buddyOrgJoinChrome(
            buddies: buddies,
            openConversation: { app.openMessages(conversationID: $0) }
        )
        .sheet(isPresented: $showPeopleSheet) {
            ActivityDetailPeopleSheet(
                activity: live,
                onOpenProfile: { profileMemberName = $0 },
                onMessage: { name in
                    startChat(
                        with: name,
                        greeting: "你好，我在「\(live.title)」活动里看到你，想认识一下。"
                    )
                }
            )
        }
        .sheet(isPresented: $showJoinConfirm) {
            ActivityJoinConfirmSheet(activity: live) { note in
                pendingJoinNote = note
                if !live.requiresInAppPayment || ActivityPaymentStore.hasPaid(for: live.id) {
                    completeJoin(for: live, note: note)
                } else {
                    showPaymentSheet = true
                }
            }
        }
        .sheet(isPresented: $showPaymentSheet) {
            ActivityPaymentSheet(activity: live) {
                completeJoin(for: live, note: pendingJoinNote)
            }
        }
        .sheet(isPresented: $showContentEditor) {
            ActivityDetailContentEditorSheet(activity: live) {
                contentRevision += 1
            }
        }
        .sheet(isPresented: $showOrders) {
            ActivityOrdersSheet(activityID: live.id) {
                ordersRevision += 1
            }
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
                if let id = cancelRefundActivityID {
                    app.cancelActivityRegistration(id, refundIfPaid: false)
                }
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelWithRefundConfirm, role: .destructive) {
                if let id = cancelRefundActivityID {
                    app.cancelActivityRegistration(id, refundIfPaid: true)
                    ordersRevision += 1
                }
                cancelRefundActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelWithRefundMessage)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar(live)
        }
    }

    @ViewBuilder
    private func detailFormSections(_ live: Activity, blueprint: ActivityDetailBlueprint) -> some View {
        let joined = model.isJoined(live.id)
        let trust = ActivityHostTrust.make(
            hostName: live.hostName,
            liveHostedCount: model.activities.filter { $0.hostName == live.hostName }.count
        )
        let paidOrder = ActivityPaymentStore.paidOrder(for: live.id)
            ?? ActivityPaymentStore.orders(for: live.id).first {
                $0.status == .refunded || $0.status == .refunding
            }

        // 标题 + 决策同一 Section：系统行距，避免两张白卡之间再叠一段分区间距
        Section {
            titleBlock(live)

            ActivityDetailDecisionCard(
                activity: live,
                viewerWaitlisted: model.isWaitlisted(live.id),
                hostNote: blueprint.hostNote,
                onPeople: { showPeopleSheet = true }
            )
        }
        .id(contentRevision)

        Section {
            ActivityDetailHostTrustRow(
                trust: trust,
                onHost: { showHostProfile = true },
                onChat: { askHost(about: live) }
            )
        } header: {
            Text(ActivityDetailCopy.peopleHostRole)
        }

        if let circle = SampleData.relatedCircle(for: live) {
            Section {
                ActivityDetailRelatedCircleRow(circle: circle)
            } header: {
                Text(ActivityDetailCopy.relatedCircleTitle)
            } footer: {
                Text(ActivityDetailCopy.relatedCircleFooter)
            }
        }

        ForEach(blueprint.sections) { section in
            Section {
                sectionBlock(section: section, blueprint: blueprint)
                    .id(section.id)
            } header: {
                Text(section.title)
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
                activityCredentialLink(for: live, joined: joined)
            }
            .id(ordersRevision)
        } else if joined {
            Section {
                activityCredentialLink(for: live, joined: joined)
            }
        }

        if revealsSecondaryContent {
            Section {
                ActivityDetailCommentsSection(
                    activityID: live.id,
                    currentUserName: model.currentUserName
                ) {
                    commentsRevision += 1
                }
            } header: {
                Text(ActivityDetailCopy.commentsTitle)
            }
            .id(commentsRevision)

            let related = ActivityRelatedRecommender.related(to: live, from: model.activities)
            if !related.isEmpty {
                Section {
                    ActivityDetailRelatedSection(relatedActivities: related)
                } header: {
                    Text(ActivityDetailCopy.relatedTitle)
                }
            }
        }
    }

    @ViewBuilder
    private func footerActions(_ live: Activity, joined: Bool) -> some View {
        let showHostEdit = isHost
        let showRecap = joined && live.isLifecycleEnded
        if showHostEdit || showRecap {
            Section {
                if showHostEdit {
                    Button {
                        showContentEditor = true
                    } label: {
                        Label(ActivityCardStatus.refineContent, systemImage: "square.and.pencil")
                    }
                }

                if showRecap {
                    Button {
                        openRecapCompose(for: live)
                    } label: {
                        Label(ActivityDetailCopy.recapCTA, systemImage: "square.and.pencil")
                    }
                }
            }
        }
    }

    // MARK: - Hero / chrome

    private func hero(_ activity: Activity) -> some View {
        let weather = LocalPlaceholderWeatherProvider.forecast(for: activity)
        let dateLine =
            "\(Formatters.monthDay.string(from: activity.date)) \(Formatters.weekday.string(from: activity.date))"
        let weatherLine = "\(weather.temperatureC)° · \(weather.conditionText)"
        let prefersStacked = DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)

        let gallery = ActivityDetailHeroGallery(
            activity: activity,
            onEditGallery: isHost ? { showContentEditor = true } : nil
        )
        .frame(maxWidth: .infinity)
        .aspectRatio(PlatformMetrics.detailHeroAspectRatio, contentMode: .fit)
        .clipped()
        .clipShape(PlatformMetrics.cardShape)

        let chip = heroWeatherChip(
            dateLine: dateLine,
            weatherLine: weatherLine,
            systemImage: weather.systemImage,
            onMedia: !prefersStacked
        )

        return Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
                    gallery
                    chip
                }
            } else {
                gallery
                    .overlay(alignment: .bottomLeading) {
                        chip.platformMediaChromeInset()
                    }
            }
        }
    }

    private func heroWeatherChip(
        dateLine: String,
        weatherLine: String,
        systemImage: String,
        onMedia: Bool
    ) -> some View {
        Button {} label: {
            HStack {
                Text(dateLine)
                Text("·")
                    .opacity(0.7)
                Label(weatherLine, systemImage: systemImage)
                    .labelStyle(.titleAndIcon)
                    .symbolRenderingMode(.hierarchical)
            }
            .font(.subheadline.weight(.medium))
        }
        .activityGlassCapsule(controlSize: .regular)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dateLine)，天气 \(weatherLine)")
    }

    @ViewBuilder
    private func moreMenuContent(for live: Activity) -> some View {
        Button(ActivityCardStatus.shareActivity, systemImage: "square.and.arrow.up") {
            showShareSheet = true
        }

        Button(ActivityDetailCopy.reportAction, systemImage: "exclamationmark.bubble", role: .destructive) {
            showReportSheet = true
        }

        Divider()

        Button {
            model.toggleFavorite(live.id)
        } label: {
            Label(
                model.isFavorite(live.id) ? ActivityCardStatus.unfavorite : ActivityCardStatus.favorite,
                systemImage: model.isFavorite(live.id) ? "bookmark.fill" : "bookmark"
            )
        }

        if isHost {
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

        if model.isJoined(live.id), !live.isFree {
            Button(ActivityDetailCopy.ordersTitle, systemImage: "doc.text") {
                showOrders = true
            }
        }
    }

    private func titleBlock(_ activity: Activity) -> some View {
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
    private func sectionBlock(
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
    private func prepBlock(_ blueprint: ActivityDetailBlueprint) -> some View {
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
    private func bottomBar(_ activity: Activity) -> some View {
        Group {
            if activity.isLifecycleEnded {
                endedBottomBar(activity)
            } else if isHost {
                hostBottomBar(activity)
            } else {
                participantBottomBar(activity)
            }
        }
        .activityDetailBottomBarChrome()
    }

    @ViewBuilder
    private func endedBottomBar(_ activity: Activity) -> some View {
        if model.isJoined(activity.id) || isHost {
            Button {
                openRecapCompose(for: activity)
            } label: {
                Label(ActivityDetailCopy.recapCTA, systemImage: "square.and.pencil")
            }
            .activityDetailBottomPrimaryCTA()
        } else {
            Label(ActivityDetailCopy.activityEnded, systemImage: "calendar.badge.clock")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    private func hostBottomBar(_ activity: Activity) -> some View {
        HStack {
            NavigationLink {
                ActivityHostManageView(activityID: activity.id)
            } label: {
                Label(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3")
            }
            .activityDetailBottomSecondaryCTA()

            Button(ActivityDetailCopy.openGroupChat) { openGroupChat(for: activity) }
                .activityDetailBottomPrimaryCTA()
        }
    }

    private func participantBottomBar(_ activity: Activity) -> some View {
        HStack {
            if model.isJoined(activity.id) {
                Button(ActivityDetailCopy.cancelRegistration) {
                    requestCancelRegistration(activity)
                }
                .activityDetailBottomSecondaryCTA()

                Button(ActivityDetailCopy.openGroupChat) { openGroupChat(for: activity) }
                    .activityDetailBottomPrimaryCTA()
            } else {
                joinPrimaryButton(activity)
            }
        }
    }

    @ViewBuilder
    private func joinPrimaryButton(_ activity: Activity) -> some View {
        let waitlisted = model.isWaitlisted(activity.id)
        let labels = ActivityDetailCopy.joinButtonLabels(
            free: activity.isFree,
            almostFull: activity.isAlmostFull,
            remaining: activity.remainingSpots,
            full: activity.isFull,
            waitlisted: waitlisted,
            hasOpenSpotFromWaitlist: !activity.isFull && waitlisted
        )

        if activity.isFull && waitlisted {
            Button(labels.primary) { _ = model.toggleWaitlist(activity.id) }
                .activityDetailBottomSecondaryCTA()
        } else if activity.isFull {
            Button(labels.primary) { _ = model.toggleWaitlist(activity.id) }
                .activityDetailBottomPrimaryCTA()
        } else if let subtitle = labels.subtitle {
            Button {
                showJoinConfirm = true
            } label: {
                VStack() {
                    Text(labels.primary)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .opacity(0.92)
                }
            }
            .activityDetailBottomPrimaryCTA()
        } else {
            Button(labels.primary) { showJoinConfirm = true }
                .activityDetailBottomPrimaryCTA()
        }
    }

    // MARK: - Success sheets

    private var joinSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.joinSuccessActivityID == activityID },
            set: { if !$0 { model.dismissJoinSuccess() } }
        )
    }

    private var publishSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.publishSuccessActivityID == activityID },
            set: { if !$0 { model.dismissPublishSuccess() } }
        )
    }

    @ViewBuilder
    private var joinSuccessSheet: some View {
        if let live = model.activity(id: activityID) {
            ActivityJoinSuccessSheet(
                activity: live,
                context: .joined,
                onOpenGroup: { openGroupChat(for: live) },
                onWriteRecap: { openRecapCompose(for: live) }
            )
        }
    }

    @ViewBuilder
    private var publishSuccessSheet: some View {
        if let live = model.activity(id: activityID) {
            ActivityJoinSuccessSheet(
                activity: live,
                context: .published,
                onOpenGroup: { openGroupChat(for: live) }
            )
        }
    }

    // MARK: - Actions

    private func shareText(for activity: Activity) -> String {
        "\(activity.title)\n\(Formatters.activityEventTime(from: activity.date))\n\(activity.location)"
    }

    private func submitReport(reason: String, detail: String, evidenceCount: Int) {
        guard let activity else { return }
        var parts = [reason, detail]
        if evidenceCount > 0 {
            parts.append("附件 \(evidenceCount) 张")
        }
        app.addModerationTicket(
            postID: activity.id,
            title: activity.title,
            reason: parts.joined(separator: " · "),
            targetKind: .activity
        )
        reportMessage = ActivityDetailCopy.reportReceivedMessage
    }

    private func askHost(about activity: Activity) {
        startChat(
            with: activity.hostName,
            greeting: ActivityDetailCopy.askHostGreeting(title: activity.title)
        )
    }

    private func openGroupChat(for activity: Activity) {
        app.openActivityGroupChat(for: activity)
    }

    private func startChat(with name: String, greeting: String) {
        if let convo = app.startDirectChat(with: name, greeting: greeting) {
            app.openMessages(conversationID: convo.id)
        }
    }

    private func openRecapCompose(for activity: Activity) {
        app.beginCommunityRecap(for: activity)
    }

    private func requestCancelRegistration(_ activity: Activity) {
        if ActivityPaymentStore.hasPaid(for: activity.id) {
            cancelRefundActivityID = activity.id
        } else {
            app.cancelActivityRegistration(activity.id)
        }
    }

    private func completeJoin(for activity: Activity, note: String?) {
        // 支付完成后再次校验名额（库存与资金一致性）
        guard let live = model.activity(id: activity.id) else {
            pendingJoinNote = nil
            return
        }

        if live.isFull || live.isLifecycleEnded {
            refundPaidOrderIfNeeded(for: live.id)
            pendingJoinNote = nil
            joinIssueMessage = ActivityDetailCopy.joinFailedFullAfterPayMessage
            return
        }

        if let note, !note.isEmpty {
            _ = app.startDirectChat(
                with: live.hostName,
                greeting: "\(ActivityDetailCopy.joinNotePrefix)\(note)"
            )
        }
        pendingJoinNote = nil

        let joined = app.toggleJoinActivity(live.id)
        if !joined {
            refundPaidOrderIfNeeded(for: live.id)
            joinIssueMessage = ActivityDetailCopy.joinFailedFullAfterPayMessage
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: live)
        }
    }

    @ViewBuilder
    private func activityCredentialLink(for live: Activity, joined: Bool) -> some View {
        if let pass = passStore.activityPass(for: live, activeOnly: true) {
            NavigationLink {
                WalletPassDetailView(passID: pass.id)
            } label: {
                Label("查看活动凭证", systemImage: "ticket")
            }
        } else if let voided = passStore.activityPass(for: live, activeOnly: false), voided.voided {
            NavigationLink {
                WalletPassDetailView(passID: voided.id)
            } label: {
                Label("凭证已作废", systemImage: "xmark.seal")
            }
        } else if joined || isHost {
            Button("补发活动凭证", systemImage: "ticket") {
                if let order = ActivityPaymentStore.paidOrder(for: live.id) {
                    _ = passStore.issueActivityTicket(order: order, activity: live)
                } else {
                    _ = passStore.issueActivityAttendanceTicket(for: live)
                }
            }
        }
    }

    private func refundPaidOrderIfNeeded(for activityID: Activity.ID) {
        guard let order = ActivityPaymentStore.paidOrder(for: activityID) else { return }
        _ = ActivityPaymentStore.requestRefund(orderID: order.id)
        ActivityPaymentStore.finalizeRefund(orderID: order.id)
        ordersRevision += 1
    }
}

#Preview("户外") {
    let app = AppModel()
    return NavigationStack {
        ActivityDetailView(
            activity: SampleData.activities.first { $0.category == .outdoorSports }!
        )
        .environment(app)
        .environment(app.activities)
        .environment(app.messages)
    }
}
