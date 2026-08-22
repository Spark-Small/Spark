//
//  ActivityDetailSections.swift
//  坐标系
//

import MapKit
import SwiftUI

/// 首屏决策卡：费用 / 时间 / 地点 / 名额 / 参加进度
struct ActivityDetailDecisionCard: View {
    let activity: Activity
    var viewerWaitlisted: Bool
    var hostNote: String? = nil
    var onPeople: () -> Void

    @State private var calendarMessage: String?
    @State private var showCalendarAccessAlert = false
    @State private var showNavigationPicker = false

    var body: some View {
        VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text(activity.fee)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Spacer()
                    Text(spotsLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(spotsColor)
                        .monospacedDigit()
                }

                VStack(alignment: .leading) {
                    decisionRow(
                        title: "时间",
                        text: Formatters.activityEventTime(from: activity.date),
                        secondary: Formatters.activityStartCountdown(from: activity.date),
                        actionSystemImage: "alarm",
                        actionLabel: ActivityDetailCopy.calendarAction
                    ) {
                        Task {
                            switch await ActivityCalendar.add(activity, withReminders: true) {
                            case .added(let withReminders):
                                calendarMessage = ActivityCalendar.successMessage(withReminders: withReminders)
                            case .accessDenied:
                                showCalendarAccessAlert = true
                            case .failed:
                                calendarMessage = ActivityDetailCopy.calendarFailedMessage
                            }
                        }
                    }

                    locationModule
                }

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let hostNote, !hostNote.isEmpty {
                    Text(hostNote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Button(action: onPeople) {
                    HStack {
                        ActivityParticipantAvatars(names: activity.displayParticipants)
                        Text(ActivityDetailCopy.socialProof(
                            joined: activity.joined,
                            capacity: activity.capacity,
                            viewerWaitlisted: viewerWaitlisted
                        ))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(ActivityDetailCopy.peopleRowAccessibility)
                .accessibilityHint("查看参加成员")
        }
        .sheet(isPresented: $showNavigationPicker) {
            ActivityNavigationPickerSheet(activity: activity)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .activityCalendarAccessAlert(isPresented: $showCalendarAccessAlert)
    }

    private var locationModule: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Label {
                    VStack(alignment: .leading) {
                        Text(activity.location)
                            .font(.body)
                        Text(activity.distanceLabel(hasUserLocation: LocationService.shared.coordinate != nil))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Text("地点")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .labelStyle(.titleAndIcon)
                .font(.body)

                Spacer(minLength: 0)

                ActivityDetailControls.GlassIconButton(
                    systemImage: "arrow.triangle.turn.up.right.diamond",
                    accessibilityLabel: ActivityDetailCopy.navigationAction
                ) {
                    showNavigationPicker = true
                }
            }

            if activity.latitude != nil, activity.longitude != nil {
                Button {
                    showNavigationPicker = true
                } label: {
                    ActivityDetailLocationPreview(activity: activity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ActivityDetailCopy.mapPreviewAccessibility)
            }
        }
    }

    private var spotsLabel: String {
        if viewerWaitlisted, !activity.isFull, !activity.isLifecycleEnded {
            return ActivityCardStatus.waitlistSpotOpen
        }
        return ActivityDetailCopy.spotsLabel(
            full: activity.isFull,
            almostFull: activity.isAlmostFull,
            remaining: activity.remainingSpots
        )
    }

    private var spotsColor: Color {
        if viewerWaitlisted, !activity.isFull, !activity.isLifecycleEnded {
            return PlatformStatus.success
        }
        return activity.isAlmostFull || activity.isFull ? PlatformStatus.warning : PlatformStatus.success
    }

    private func decisionRow(
        title: String,
        text: String,
        secondary: String,
        actionSystemImage: String,
        actionLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center) {
            Label {
                VStack(alignment: .leading) {
                    Text(text)
                        .font(.body)
                    Text(secondary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .labelStyle(.titleAndIcon)
            .font(.body)

            Spacer(minLength: 0)

            ActivityDetailControls.GlassIconButton(
                systemImage: actionSystemImage,
                accessibilityLabel: actionLabel,
                action: action
            )
        }
    }
}

/// 发起人：Form 行内默认 VStack + 系统 HStack 间距（与资料页身份行一致）
struct ActivityDetailHostTrustRow: View {
    let trust: ActivityHostTrust
    var onHost: () -> Void
    var onChat: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button(action: onHost) {
                HStack(alignment: .center) {
                    PlatformListAvatarView(name: trust.name)
                    VStack(alignment: .leading) {
                        HStack {
                            Text(trust.name)
                            Text(trust.levelText)
                                .foregroundStyle(.secondary)
                            if trust.isVerified {
                                Image(systemName: TrustBadgeKind.photoVerified.systemImage)
                                    .foregroundStyle(.tint)
                                    .symbolRenderingMode(.hierarchical)
                                    .accessibilityLabel(TrustBadgeKind.photoVerified.title)
                            }
                            if trust.isMember {
                                Image(systemName: TrustBadgeKind.activeMember.systemImage)
                                    .foregroundStyle(.secondary)
                                    .symbolRenderingMode(.hierarchical)
                                    .accessibilityLabel(TrustBadgeKind.activeMember.title)
                            }
                        }
                        .font(.body)
                        .lineLimit(1)
                        Text(trust.metricsLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilitySummary)

            ActivityDetailControls.GlassIconButton(
                systemImage: "bubble.left",
                accessibilityLabel: ActivityDetailCopy.hostMessageAccessibility,
                action: onChat
            )
        }
    }

    private var accessibilitySummary: String {
        var parts = [trust.name]
        parts.append(trust.levelText)
        if trust.isVerified { parts.append(TrustBadgeKind.photoVerified.title) }
        if trust.isMember { parts.append(TrustBadgeKind.activeMember.title) }
        parts.append(trust.hostedText)
        parts.append(trust.completionText)
        return parts.joined(separator: "，")
    }
}


// MARK: - Content blocks

/// 详情有序步骤：统一用 SF Symbols 空心序号圆（与须知 / 准备一致）
enum ActivityDetailStepSymbol {
    static func systemName(_ step: Int) -> String {
        (1...50).contains(step) ? "\(step).circle" : "circle"
    }
}

/// 详情正文行：图标 + 内容，系统 HStack 默认间距
private struct ActivityDetailSectionRow<Icon: View, Content: View>: View {
    var alignment: VerticalAlignment = .top
    @ViewBuilder var icon: () -> Icon
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: alignment) {
            icon()
            content()
        }
        .font(.body)
    }
}

struct ActivityDetailTimelineCard: View {
    let items: [ActivityDetailTimelineItem]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let step = index + 1
                ActivityDetailSectionRow {
                    Image(systemName: ActivityDetailStepSymbol.systemName(step))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                } content: {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(item.time)
                                .monospacedDigit()
                            Text(item.title)
                        }
                        .foregroundStyle(.primary)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityLabel("\(step). \(item.time)，\(item.title)。\(item.detail)")
            }
        }
    }
}

struct ActivityDetailFeeCard: View {
    let included: [ActivityDetailChecklistItem]
    let excluded: [ActivityDetailChecklistItem]
    let refundNotes: [String]

    var body: some View {
        VStack(alignment: .leading) {
            if !included.isEmpty {
                checklistGroup(title: "费用包含", items: included)
            }
            if !excluded.isEmpty {
                checklistGroup(title: "费用不含", items: excluded)
            }
            if !refundNotes.isEmpty {
                VStack(alignment: .leading) {
                    Text("变更与退款")
                        .font(.body)
                        .foregroundStyle(.primary)
                    ForEach(Array(refundNotes.enumerated()), id: \.offset) { _, note in
                        ActivityDetailSectionRow {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        } content: {
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func checklistGroup(title: String, items: [ActivityDetailChecklistItem]) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            ForEach(items) { item in
                ActivityDetailSectionRow {
                    if item.included {
                        Image(systemName: "checkmark.circle.fill")
                            .platformSymbolStyle(.status(PlatformStatus.success))
                    } else {
                        Image(systemName: "circle")
                            .platformSymbolStyle(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                } content: {
                    Text(item.text)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct ActivityDetailGearGrid: View {
    let items: [ActivityDetailGearItem]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(items) { item in
                ActivityDetailSectionRow {
                    Image(systemName: item.systemImage)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                } content: {
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .foregroundStyle(.primary)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct ActivityDetailNumberedNotes: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                let step = index + 1
                ActivityDetailSectionRow {
                    Image(systemName: ActivityDetailStepSymbol.systemName(step))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                } content: {
                    Text(note)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityLabel("\(step). \(note)")
            }
        }
    }
}

struct ActivityDetailPeopleSheet: View {
    let activity: Activity

    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    @State private var memberContactRoute: PeerContactRoute?

    private var members: [String] {
        var names = [activity.hostName]
        for name in activity.displayParticipants where !names.contains(name) {
            names.append(name)
        }
        return names
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(Array(members.enumerated()), id: \.offset) { index, name in
                        HStack {
                            NavigationLink(value: name) {
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(index == 0 ? ActivityDetailCopy.peopleHostRole : ActivityDetailCopy.peopleMemberRole)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    PlatformListAvatarView(name: name)
                                }
                                .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.plain)

                            Spacer(minLength: 0)

                            ActivityDetailControls.GlassIconButton(
                                systemImage: "bubble.left",
                                accessibilityLabel: "私信\(name)"
                            ) {
                                openMemberChat(with: name)
                            }
                        }
                    }
                } header: {
                    Text("共 \(activity.joined) 人参与")
                } footer: {
                    if members.count < activity.joined {
                        Text("已展示 \(members.count) 位伙伴。\(ActivityDetailCopy.peopleSheetFooter)")
                    } else {
                        Text(ActivityDetailCopy.peopleSheetFooter)
                    }
                }
            }
            .navigationTitle("活动成员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    peopleSheetBackButton(dismissesSheet: true)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActivityDetailCopy.peopleSheetDone) {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: String.self) { name in
                memberProfile(name)
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            peopleSheetBackButton(dismissesSheet: false)
                        }
                    }
            }
            .peerContactDestination(route: $memberContactRoute)
        }
        .independentNavigationSheetChrome()
        .platformSheet(.browser)
    }

    @ViewBuilder
    private func memberProfile(_ name: String) -> some View {
        let context: ConversationChatContext = name == activity.hostName
            ? .activityHost(activityID: activity.id)
            : .activityMember(activityID: activity.id)
        if let item = buddies.item(for: name) {
            BuddyDetailRouteView(item: item)
        } else {
            CommunityAuthorProfileView(
                name: name,
                chatContextOverride: context
            )
        }
    }

    private func openMemberChat(with name: String) {
        let context: ConversationChatContext = name == activity.hostName
            ? .activityHost(activityID: activity.id)
            : .activityMember(activityID: activity.id)
        memberContactRoute = app.openPeerContact(with: name, context: context)
    }

    private func peopleSheetBackButton(dismissesSheet: Bool) -> some View {
        Button {
            if dismissesSheet {
                dismiss()
            } else {
                path.removeLast()
            }
        } label: {
            Label(ActivityDetailCopy.peopleSheetBack, systemImage: "chevron.left")
        }
        .accessibilityHint(
            dismissesSheet
                ? "关闭活动成员列表"
                : "返回活动成员列表"
        )
    }
}

// MARK: - Hero / 相册

struct ActivityDetailHeroGallery: View {
    let activity: Activity
    var onEditGallery: (() -> Void)?

    @State private var preview: CommunityPhotoDestination?

    private var photos: [CommunityPhotoRef] {
        ActivityDetailContentStore.galleryPhotos(for: activity)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            photoLayer
                .clipShape(PlatformMetrics.cardShape)
                .contentShape(PlatformMetrics.cardShape)
                .onTapGesture {
                    openPreview(at: 0)
                }

            // 控件单独一层，避免被头图 onTapGesture 抢走点击
            HStack() {
                if photos.count > 1 {
                    Button {
                        openPreview(at: 0)
                    } label: {
                        Label(CommunityMediaCopy.countChip(photos), systemImage: "photo.on.rectangle.angled")
                    }
                    .labelStyle(.titleAndIcon)
                    .activityGlassChip()
                }

                if let onEditGallery {
                    Button(action: onEditGallery) {
                        Label("编辑相册", systemImage: "square.and.pencil")
                    }
                    .labelStyle(.titleAndIcon)
                    .activityGlassChip()
                }
            }
            .platformMediaChromeInset()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .communityPhotoCover($preview)
    }

    private func openPreview(at index: Int) {
        guard !photos.isEmpty else { return }
        preview = CommunityPhotoDestination(photos: photos, startIndex: index)
    }

    /// 与发现卡同源单帧封面；多图进全屏查看器翻页
    @ViewBuilder
    private var photoLayer: some View {
        if let first = photos.first {
            CommunityRemotePhoto(ref: first)
        } else {
            CommunityRemotePhoto(ref: .seeded(seed: activity.coverSeed, symbol: activity.coverSymbol))
        }
    }
}

// MARK: - 评论

/// 活动评论 Sheet：与社区同款 List + 底栏输入。
struct ActivityCommentsSheet: View {
    let activityID: Activity.ID
    let hostName: String
    let currentUserName: String
    var onChanged: () -> Void = {}

    @State private var refreshID = 0

    @Environment(\.dismiss) private var dismiss

    private var rootCount: Int {
        PlatformReviewsStore.reviews(for: .activity(activityID)).filter(\.isRoot).count
    }

    var body: some View {
        NavigationStack {
            PlatformReviewsCommentsHost(
                target: .activity(activityID),
                currentUserName: currentUserName,
                layout: .sheetList,
                contentOwnerName: hostName,
                ownerBadgeTitle: "发起人",
                emptyTitle: ActivityDetailCopy.commentsEmpty,
                emptyHint: ActivityDetailCopy.commentsEmptyHint,
                placeholder: ActivityDetailCopy.commentsPlaceholder,
                onChanged: {
                    refreshID += 1
                    onChanged()
                }
            )
            .id(refreshID)
            .navigationTitle(rootCount == 0 ? "评论" : "评论 \(rootCount)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(MessagesCopy.close) { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }
}

/// 详情页评论摘要：最多 2 条预览 + 进入完整评论区。
struct ActivityDetailCommentsPreviewSection: View {
    let activityID: Activity.ID
    let hostName: String
    var onOpenComments: () -> Void

    private var reviews: [PlatformReview] {
        PlatformReviewsStore.reviews(for: .activity(activityID))
    }

    private var rootCount: Int {
        reviews.filter(\.isRoot).count
    }

    private var previewRoots: [PlatformReview] {
        Array(PlatformReviewCatalog.sortedRoots(reviews).prefix(2))
    }

    var body: some View {
        Section {
            VStack(alignment: .leading) {
                if previewRoots.isEmpty {
                    Text(ActivityDetailCopy.commentsEmptyHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button(action: onOpenComments) {
                        VStack(alignment: .leading) {
                            ForEach(previewRoots) { review in
                                CommunityCommentRow(
                                    comment: review.asCommunityComment,
                                    style: .thread,
                                    showsLike: false,
                                    showsTranslate: false,
                                    contentOwnerName: hostName,
                                    ownerBadgeTitle: "发起人"
                                )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onOpenComments) {
                    Label(
                        rootCount == 0
                            ? ActivityDetailCopy.commentsWriteFirst
                            : ActivityDetailCopy.commentsViewAll,
                        systemImage: "bubble.right"
                    )
                }
            }
        } header: {
            Text(ActivityDetailCopy.commentsCountTitle(rootCount))
        }
    }
}

// MARK: - 相关活动 / 凭证

/// Form 清单行：左 leading + 主副文（相关活动、相关圈子等同构）
private struct ActivityDetailFormLinkRow<Leading: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var leading: () -> Leading

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            leading()
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// 相关活动横滑轨（仅内容；Section header 由调用方提供，与「活动评论」同构）
struct DetailRelatedActivitiesRail: View {
    let activities: [Activity]

    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @State private var openedActivityID: Activity.ID?

    var body: some View {
        DiscoverHorizontalRail(
            spacing: 0,
            appliesHorizontalMargins: false
        ) {
            ForEach(activities) { activity in
                PlatformEventCard(
                    activityID: activity.id,
                    photo: activity.coverPhoto,
                    badge: ActivityCardStatus.hotBadge(for: activity),
                    title: activity.title,
                    timeLine: Formatters.activityEventTime(from: activity.date),
                    metaLine: ActivityCardStatus.hotMetaLine(for: activity),
                    isJoined: model.isJoined(activity.id),
                    isFull: activity.isFull,
                    onCoverTap: { openedActivityID = activity.id },
                    onJoin: model.isJoined(activity.id) ? nil : {
                        _ = app.quickJoinActivity(activity) {
                            openedActivityID = activity.id
                        }
                    }
                )
                .clipShape(PlatformMetrics.fullBleedShape)
                .containerRelativeFrame(.horizontal) { length, _ in length }
            }
        }
        .platformFormEdgeToEdgeRow()
        .navigationDestination(item: $openedActivityID) { id in
            ActivityDetailView(activityID: id)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}

/// 已参加 → 订单区下方活动凭证 Section
struct ActivityDetailCredentialSection: View {
    let activity: Activity
    let isHost: Bool
    @Binding var ordersRevision: Int

    @Environment(ActivitiesModel.self) private var model
    @Environment(WalletPassStore.self) private var passStore

    var body: some View {
        let joined = model.isJoined(activity.id)
        let showsCredential = joined
            || (ActivityPaymentStore.displayOrder(for: activity.id) != nil && isHost)

        if showsCredential {
            Section {
                credentialContent(joined: joined)
            } header: {
                Text(ActivityDetailCopy.credentialSectionTitle)
            }
            .id(ordersRevision)
        }
    }

    @ViewBuilder
    private func credentialContent(joined: Bool) -> some View {
        if let pass = passStore.activityPass(for: activity, activeOnly: true) {
            NavigationLink {
                WalletPassDetailView(passID: pass.id)
            } label: {
                ProfileActivityCredentialStrip(activity: activity)
            }
            .platformWalletPassCredentialRow()
            .accessibilityLabel(ActivityDetailCopy.credentialViewAction)
        } else if let voided = passStore.activityPass(for: activity, activeOnly: false), voided.voided {
            NavigationLink {
                WalletPassDetailView(passID: voided.id)
            } label: {
                ProfileActivityCredentialStrip(activity: activity, voided: true)
            }
            .platformWalletPassCredentialRow()
            .accessibilityLabel(ActivityDetailCopy.credentialVoidedAction)
        } else if joined || isHost {
            Button(ActivityDetailCopy.credentialReissueAction, systemImage: "ticket") {
                reissueCredential()
            }
        }
    }

    private func reissueCredential() {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            _ = passStore.issueActivityTicket(order: order, activity: activity)
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: activity)
        }
        ordersRevision += 1
    }
}

/// 活动详情 → 相关兴趣圈子入口
struct ActivityDetailRelatedCircleRow: View {
    let circle: InterestCircle

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var subtitle: String {
        "\(circle.city) · \(circle.topic) · \(circle.memberCount) 人"
    }

    var body: some View {
        NavigationLink(value: CircleBrowseRoute.circle(circle)) {
            ActivityDetailFormLinkRow(title: circle.name, subtitle: subtitle) {
                Image(systemName: circle.systemImage)
                    .font(.title2)
                    .platformContentSymbolStyle()
                    .frame(
                        width: dynamicTypeSize.listAvatarSide,
                        height: dynamicTypeSize.listAvatarSide
                    )
                    .background(Color.accentColor.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(circle.name)，\(subtitle)")
    }
}

struct ActivityDetailLocationPreview: View {
    let activity: Activity

    @ViewBuilder
    var body: some View {
        if let lat = activity.latitude, let lon = activity.longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            ))) {
                Marker(activity.location, coordinate: coordinate)
            }
            .platformDetailMapPreview()
            .mapStyle(.standard(elevation: .realistic))
            .allowsHitTesting(false)
        }
    }
}

