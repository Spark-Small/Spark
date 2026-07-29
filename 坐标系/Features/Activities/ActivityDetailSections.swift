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
                            calendarMessage = await ActivityCalendar.add(activity, withReminders: true)
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
        }
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

/// 发起人：系统副标题单元格 — 头像与双行文案垂直居中，图文水平间距由 HStack 默认系统间距承担
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
                        nameBadgesRow
                        metricsRow
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

    /// 第一行：名称与徽章同一文本基线
    private var nameBadgesRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(trust.name)

            if trust.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel("已认证")
            }
            if trust.isMember {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel("会员")
            }
            Text(trust.levelText)
                .foregroundStyle(.secondary)
                .accessibilityLabel("等级 \(trust.level)")
        }
        .font(.body)
        .lineLimit(1)
    }

    /// 第二行：单行不换行，避免「场」孤行导致文案块变高、相对头像视觉失中
    private var metricsRow: some View {
        Text(trust.metricsLine)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var accessibilitySummary: String {
        var parts = [trust.name]
        if trust.isVerified { parts.append("已认证") }
        if trust.isMember { parts.append("会员") }
        parts.append(trust.levelText)
        parts.append(trust.hostedText)
        parts.append(trust.completionText)
        parts.append("评分 \(trust.ratingText)")
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

struct ActivityDetailTimelineCard: View {
    let items: [ActivityDetailTimelineItem]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let step = index + 1
                Label {
                    VStack(alignment: .leading) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.time)
                                .monospacedDigit()
                            Text(item.title)
                        }
                        .font(.body)
                        .foregroundStyle(.primary)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: ActivityDetailStepSymbol.systemName(step))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .labelStyle(.titleAndIcon)
                .font(.body)
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
                        Label {
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .labelStyle(.titleAndIcon)
                        .font(.body)
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
                Label {
                    Text(item.text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: item.included ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.included ? PlatformStatus.success : .secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .labelStyle(.titleAndIcon)
                .font(.body)
            }
        }
    }
}

struct ActivityDetailGearGrid: View {
    let items: [ActivityDetailGearItem]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(items) { item in
                Label {
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: item.systemImage)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .labelStyle(.titleAndIcon)
                .font(.body)
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
                Label {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: ActivityDetailStepSymbol.systemName(step))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .labelStyle(.titleAndIcon)
                .font(.body)
                .accessibilityLabel("\(step). \(note)")
            }
        }
    }
}

struct ActivityDetailPeopleSheet: View {
    let activity: Activity
    var onOpenProfile: (String) -> Void
    var onMessage: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var members: [String] {
        var names = [activity.hostName]
        for name in activity.displayParticipants where !names.contains(name) {
            names.append(name)
        }
        return names
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(members.enumerated()), id: \.offset) { index, name in
                        HStack() {
                            Button {
                                onOpenProfile(name)
                            } label: {
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

                            if index == 0 {
                                Text(ActivityDetailCopy.peopleOrganizerBadge)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tint)
                            }

                            ActivityDetailControls.GlassIconButton(
                                systemImage: "bubble.left",
                                accessibilityLabel: "私信\(name)"
                            ) {
                                onMessage(name)
                                dismiss()
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .platformSheet(.browser)
    }
}

// MARK: - Hero / 相册

struct ActivityDetailHeroGallery: View {
    let activity: Activity
    var onEditGallery: (() -> Void)?

    @State private var selectedIndex = 0
    @State private var showViewer = false

    private var photos: [CommunityPhotoRef] {
        ActivityDetailContentStore.galleryPhotos(for: activity)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            photoLayer
                .onTapGesture {
                    guard !photos.isEmpty else { return }
                    showViewer = true
                }

            // 控件单独一层，避免被头图 onTapGesture 抢走点击
            HStack() {
                if photos.count > 1 {
                    Button {
                        showViewer = true
                    } label: {
                        Label("\(photos.count) 张", systemImage: "photo.on.rectangle.angled")
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
        .fullScreenCover(isPresented: $showViewer) {
            CommunityPhotoViewer(
                photos: photos,
                startIndex: selectedIndex
            )
        }
    }

    @ViewBuilder
    private var photoLayer: some View {
        if photos.count > 1 {
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, ref in
                    CommunityRemotePhoto(ref: ref)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        } else if let first = photos.first {
            CommunityRemotePhoto(ref: first)
        } else {
            CommunityRemotePhoto(ref: .seeded(seed: activity.coverSeed, symbol: activity.coverSymbol))
        }
    }
}

// MARK: - 评论 / 推荐

struct ActivityDetailCommentsSection: View {
    let activityID: Activity.ID
    let currentUserName: String
    var onChanged: () -> Void

    @State private var draft = ""
    @State private var comments: [ActivityComment] = []
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading) {
            if comments.isEmpty {
                Text(ActivityDetailCopy.commentsEmpty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading) {
                    ForEach(comments) { comment in
                        HStack(alignment: .center) {
                            // 与发起人一致：自定义头像用 HStack 居中，避免 Label 对 UIViewRepresentable 垂直失准
                            HStack(alignment: .center) {
                                PlatformListAvatarView(name: comment.author)
                                VStack(alignment: .leading) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(comment.author)
                                            .font(.body)
                                        Text(Formatters.conversationListTime(from: comment.postedAt))
                                            .font(.subheadline)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .lineLimit(1)
                                    Text(comment.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if comment.isOwned(by: currentUserName) {
                                ActivityDetailControls.GlassIconButton(
                                    systemImage: "trash",
                                    accessibilityLabel: "删除评论",
                                    role: .destructive
                                ) {
                                    ActivityCommentsStore.delete(
                                        commentID: comment.id,
                                        activityID: activityID,
                                        author: currentUserName
                                    )
                                    reload()
                                    onChanged()
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            HStack() {
                TextField(ActivityDetailCopy.commentsPlaceholder, text: $draft, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...3)
                    .focused($focused)
                ActivityDetailControls.GlassIconButton(
                    systemImage: "paperplane.fill",
                    accessibilityLabel: "发送",
                    prominent: true,
                    action: send
                )
                .disabled(!canSend)
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        comments = ActivityCommentsStore.comments(for: activityID)
    }

    private func send() {
        if let error = ActivityCommentsStore.add(draft, activityID: activityID, author: currentUserName) {
            draft = error
            return
        }
        draft = ""
        reload()
        onChanged()
    }
}

/// 相关活动：Form 副标题行（封面 + 主/副文垂直居中；disclosure 交给系统 NavigationLink）
struct ActivityDetailRelatedSection: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.activityZoomNamespace) private var zoomNamespace

    let relatedActivities: [Activity]

    var body: some View {
        Group {
            if let zoomNamespace {
                DiscoverHorizontalRail {
                    ForEach(relatedActivities) { related in
                        PlatformContinueCard(
                            activityID: related.id,
                            zoomNamespace: zoomNamespace,
                            photo: related.coverPhoto,
                            title: related.title,
                            timeLine: Formatters.activityEventTime(from: related.date),
                            metaLine: subtitle(for: related),
                            isJoined: model.isJoined(related.id),
                            isFull: related.isFull,
                            onJoin: model.isJoined(related.id) ? nil : { model.toggleJoin(related.id) }
                        )
                        .platformContinueRailFrame()
                    }
                }
            } else {
                DiscoverHorizontalRail {
                    ForEach(relatedActivities) { related in
                        relatedFallbackCard(related)
                            .platformContinueRailFrame()
                    }
                }
            }
        }
        .listRowInsets(relatedRailInsets)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    /// Form 行负水平 inset，页边交给 `DiscoverHorizontalRail`
    private var relatedRailInsets: EdgeInsets {
        let horizontal = PlatformMetrics.contentInset
        return EdgeInsets(
            top: PlatformMetrics.sectionHeaderSpacing,
            leading: -horizontal,
            bottom: PlatformMetrics.sectionHeaderSpacing,
            trailing: -horizontal
        )
    }

    private func relatedFallbackCard(_ related: Activity) -> some View {
        NavigationLink(value: related.id) {
            VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                CommunityRemotePhoto(ref: related.coverPhoto)
                    .aspectRatio(PlatformMetrics.continueCardAspectRatio, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(PlatformMetrics.posterShape)

                VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                    Text(related.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    Text(subtitle(for: related))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: related))
    }

    private func subtitle(for activity: Activity) -> String {
        let fee = activity.isFree ? ActivityCardStatus.free : activity.fee
        let distance = activity.distanceLabel(
            hasUserLocation: LocationService.shared.coordinate != nil
        )
        return "\(activity.location) · \(fee) · \(distance)"
    }

    private func accessibilityLabel(for activity: Activity) -> String {
        "\(activity.title)，\(Formatters.activityEventTime(from: activity.date))，\(subtitle(for: activity))"
    }
}

/// 活动详情 → 相关兴趣组织入口（群资料 / 加入进群）
struct ActivityDetailRelatedCircleRow: View {
    let circle: InterestCircle

    @Environment(BuddiesModel.self) private var buddies
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isJoined: Bool { buddies.isJoined(circle) }

    private var actionTitle: String {
        isJoined ? ActivityDetailCopy.relatedCircleJoined : ActivityDetailCopy.relatedCircleJoin
    }

    private var subtitle: String {
        "\(circle.city) · \(circle.topic) · \(circle.memberCount) 人"
    }

    var body: some View {
        HStack(alignment: .center) {
            NavigationLink(value: circle) {
                HStack(alignment: .center) {
                    Image(systemName: circle.systemImage)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.tertiarySystemFill))
                        .platformRelatedThumb()
                        .accessibilityHidden(true)

                    VStack(alignment: .leading) {
                        Text(circle.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationLinkIndicatorVisibility(.hidden)
            .accessibilityLabel("\(circle.name)，\(subtitle)")

            NavigationLink(value: circle) {
                Text(actionTitle)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(isJoined ? .secondary : .accentColor)
            .accessibilityLabel(actionTitle)
        }
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

/// 底部弹出：选择导航 App（系统 List）
struct ActivityNavigationPickerSheet: View {
    let activity: Activity

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button("Apple 地图") {
                    ActivityNavigation.openInAppleMaps(activity)
                    dismiss()
                }
                Button("高德地图") {
                    ActivityNavigation.openInAmap(activity)
                    dismiss()
                }
                Button("百度地图") {
                    ActivityNavigation.openInBaiduMaps(activity)
                    dismiss()
                }
            }
            .navigationTitle(ActivityDetailCopy.navigationSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }
}
