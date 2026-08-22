//
//  BuddyDetailSections.swift
//  坐标系
//
//  搭子详情 Form 分区：对齐活动详情字阶 / 行结构；补全交友向资料展示。
//

import SwiftUI

// MARK: - Hero

struct BuddyDetailHeroGallery: View {
    let profile: BuddyProfile
    var verifiedBadge: Bool = false

    private var showsDistanceChip: Bool { PrivacyPreferences.showDistance }

    private var distanceChipTitle: String {
        "\(BuddyDetailCopy.distanceChipPrefix) · \(profile.distanceText)"
    }

    var body: some View {
        DetailHeroChrome(showsChip: showsDistanceChip) {
            BuddyDetailPhotoGallery(profile: profile, verifiedBadge: verifiedBadge)
        } chip: { onMedia in
            DetailHeroInfoChip(
                title: distanceChipTitle,
                systemImage: "location.fill",
                onMedia: onMedia
            )
        }
    }
}

/// 搭子详情头图相册（对齐 `ActivityDetailHeroGallery`：仅封面 + 右下控件）。
private struct BuddyDetailPhotoGallery: View {
    let profile: BuddyProfile
    var verifiedBadge: Bool = false

    @State private var preview: CommunityPhotoDestination?

    private var photos: [CommunityPhotoRef] { profile.photoRefs }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            photoLayer
                .clipShape(PlatformMetrics.cardShape)
                .contentShape(PlatformMetrics.cardShape)
                .onTapGesture {
                    openPreview(at: 0)
                }

            if photos.count > 1 {
                HStack {
                    Button {
                        openPreview(at: 0)
                    } label: {
                        Label(CommunityMediaCopy.countChip(photos), systemImage: "photo.on.rectangle.angled")
                    }
                    .labelStyle(.titleAndIcon)
                    .activityGlassChip()
                }
                .platformMediaChromeInset()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            if verifiedBadge {
                PlatformMediaCaptionBadge(title: BuddyDetailCopy.verifiedBadge, tint: .accentColor)
                    .platformMediaChromeInset()
            }
        }
        .communityPhotoCover($preview)
        .accessibilityLabel("\(profile.nickname)的照片")
    }

    private func openPreview(at index: Int) {
        guard !photos.isEmpty else { return }
        preview = CommunityPhotoDestination(photos: photos, startIndex: index)
    }

    @ViewBuilder
    private var photoLayer: some View {
        if let first = photos.first {
            CommunityRemotePhoto(ref: first)
        } else {
            CommunityRemotePhoto(ref: .seeded(seed: abs(profile.id.hashValue % 9000) + 100, symbol: "person.fill"))
        }
    }
}

// MARK: - Identity

struct BuddyDetailProfileStat: Identifiable, Hashable {
    let id: String
    var value: String
    var label: String
}

struct BuddyDetailProfileHeaderConfig {
    var statusLine: String?
    var statusTint: Color = .secondary
    var traitTags: [String] = []
    var stats: [BuddyDetailProfileStat] = []
    var hotBadge: BuddyPaidHotBadge?
    var isVerified = false
    var isOnline = false
    var showsVoicePlay = false
    var rankIconCount = 0
}

@MainActor
enum BuddyDetailProfileHeaderFactory {
    static func free(buddy: CircleBuddy) -> BuddyDetailProfileHeaderConfig {
        let profile = buddy.profile
        let isOnline = buddy.isOnline && PrivacyPreferences.showOnline

        return BuddyDetailProfileHeaderConfig(
            statusLine: isOnline ? BuddyDetailCopy.online : nil,
            statusTint: PlatformStatus.success,
            traitTags: Array(profile.tags.prefix(3)),
            stats: [],
            isOnline: isOnline
        )
    }

    static func paid(companion: PaidCompanion) -> BuddyDetailProfileHeaderConfig {
        let profile = companion.profile
        let rankIcons = min(3, max(1, companion.orderCount / 40))
        let highlights = BuddyPaidMarketCatalog.leaderboardHighlights(for: companion, limit: 2)
        let tags = Array(profile.tags.prefix(1))

        return BuddyDetailProfileHeaderConfig(
            statusLine: companion.isAvailable
                ? BuddyDetailCopy.available
                : BuddyDetailCopy.unavailable,
            statusTint: companion.isAvailable ? PlatformStatus.success : .secondary,
            traitTags: tags + highlights,
            stats: [],
            hotBadge: BuddyPaidHotBadge.forCompanion(companion, rank: 1),
            isVerified: companion.isVerified,
            showsVoicePlay: companion.serviceType == .voice,
            rankIconCount: rankIcons
        )
    }
}

struct BuddyDetailTraitChip: View {
    let title: String
    var systemImage: String
    var tint: Color

    var body: some View {
        HStack(spacing: PlatformMetrics.hairlineSpacing) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

struct BuddyDetailProfileHeader: View {
    let profile: BuddyProfile
    let config: BuddyDetailProfileHeaderConfig
    var groupAlias: String? = nil
    var showsFollow = false
    var isFollowing = false
    var onToggleFollow: (() -> Void)?

    @Environment(AppModel.self) private var app
    @Environment(CommunityModel.self) private var community

    private var displayNickname: String {
        GroupNicknameDisplay.formatted(realName: profile.nickname, groupAlias: groupAlias)
    }

    private var publicID: String {
        UserPublicID.formatDisplay(UserPublicID.code(for: profile.id))
    }

    private var cityLabel: String {
        profile.city.components(separatedBy: " · ").first ?? profile.city
    }

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
                    avatar

                    VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                        titleRow
                        metaRow
                        if !displayTraitTags.isEmpty {
                            traitRow
                        }
                    }
                }

                if showsFollow {
                    Spacer(minLength: 0)
                    followButton
                }
            }

            ProfileSocialStatsRow(
                postCount: ProfileSocialStats.postCount(for: profile.nickname, community: community),
                followingCount: ProfileSocialStats.followingCount(for: profile.nickname, app: app),
                fansCount: ProfileSocialStats.fansCount(for: profile.nickname, app: app)
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            CommunityRemotePhoto(ref: profile.coverPhoto)
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.separator).opacity(0.35), lineWidth: 1)
                }

            if config.showsVoicePlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.purple.opacity(0.92), in: Circle())
                    .overlay {
                        Circle().strokeBorder(Color(.systemBackground), lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
                    .accessibilityLabel("语音陪聊")
            } else if config.isOnline {
                Circle()
                    .fill(PlatformStatus.success)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle().strokeBorder(Color(.systemBackground), lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
                    .accessibilityLabel(BuddyDetailCopy.online)
            }
        }
        .accessibilityHidden(true)
    }

    private var titleRow: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.minContentGap) {
            Text(displayNickname)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            genderAgeBadge

            if let statusLine = config.statusLine {
                Text(statusLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(config.statusTint)
                    .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
                    .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
                    .background(config.statusTint.opacity(0.12), in: Capsule())
            }

            Spacer(minLength: 0)

            if config.rankIconCount > 0 {
                rankStack
            }
        }
    }

    private var genderAgeBadge: some View {
        HStack(spacing: 2) {
            Text(profile.gender.symbol)
                .font(.caption2.weight(.bold))
            Text("\(profile.age)")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .background(profile.gender.tint.opacity(0.88), in: Capsule())
        .accessibilityLabel("\(profile.gender.rawValue)，\(BuddyDetailCopy.ageValue(profile.age))")
    }

    private var rankStack: some View {
        HStack(spacing: -PlatformMetrics.hairlineSpacing) {
            ForEach(0..<config.rankIconCount, id: \.self) { index in
                Image(systemName: "medal.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.accentColor.opacity(0.92 - Double(index) * 0.12), in: Circle())
                    .overlay {
                        Circle().strokeBorder(Color(.systemBackground), lineWidth: 1.5)
                    }
            }
        }
        .accessibilityLabel("陪玩等级")
    }

    private var metaRow: some View {
        HStack(spacing: PlatformMetrics.minContentGap) {
            Text("\(BuddyDetailCopy.profileIDPrefix):\(publicID)")
                .lineLimit(1)
            Text("·")
                .foregroundStyle(.quaternary)
            Label(cityLabel, systemImage: "mappin.and.ellipse")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var displayTraitTags: [String] {
        Array(config.traitTags.prefix(3))
    }

    private var traitRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                if let hotBadge = config.hotBadge {
                    BuddyDetailTraitChip(
                        title: hotBadge.rawValue,
                        systemImage: "flame.fill",
                        tint: hotBadge.tint
                    )
                }
                if config.isVerified {
                    BuddyDetailTraitChip(
                        title: BuddyDetailCopy.verifiedBadge,
                        systemImage: "checkmark.seal.fill",
                        tint: Color.accentColor
                    )
                }
                ForEach(Array(displayTraitTags.enumerated()), id: \.offset) { index, tag in
                    let style = BuddyDetailProfileHeaderFactory.traitStyle(for: tag, index: index)
                    BuddyDetailTraitChip(
                        title: tag,
                        systemImage: style.icon,
                        tint: style.tint
                    )
                }
            }
        }
    }

    private var followButton: some View {
        Button {
            onToggleFollow?()
        } label: {
            Text(isFollowing ? "已关注" : "关注")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
        }
        .buttonStyle(.borderedProminent)
        .tint(isFollowing ? Color(.tertiarySystemFill) : .accentColor)
        .foregroundStyle(isFollowing ? Color.secondary : Color.white)
        .controlSize(.small)
    }
}

extension BuddyDetailProfileHeaderFactory {
    static func traitStyle(for tag: String, index: Int) -> (icon: String, tint: Color) {
        let presets: [(String, Color)] = [
            ("sparkles", .purple),
            ("leaf.fill", .pink),
            ("heart.fill", .orange),
            ("star.fill", .yellow),
            ("figure.run", .mint),
            ("camera.fill", .teal)
        ]
        if tag.localizedCaseInsensitiveContains("语音") || tag.localizedCaseInsensitiveContains("声音") {
            return ("waveform", .purple)
        }
        if tag.localizedCaseInsensitiveContains("徒步") || tag.localizedCaseInsensitiveContains("运动") {
            return ("figure.hiking", .mint)
        }
        let preset = presets[index % presets.count]
        return (BuddyHobbyOption.systemImage(for: tag), preset.1)
    }
}

// MARK: - Basic info

private struct BuddyDetailFieldLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
    }
}

struct BuddyDetailBasicInfoSection: View {
    let profile: BuddyProfile

    var body: some View {
        LabeledContent {
            Text(profile.gender.rawValue)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.genderLabel, systemImage: "person.fill")
        }
        LabeledContent {
            Text(BuddyDetailCopy.ageValue(profile.age))
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.ageLabel, systemImage: "numbers")
        }
        LabeledContent {
            Text(profile.heightText)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.heightLabel, systemImage: "ruler")
        }
        LabeledContent {
            Text(profile.weightText)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.weightLabel, systemImage: "scalemass")
        }
        LabeledContent {
            Text(profile.city)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.cityLabel, systemImage: "mappin.and.ellipse")
        }
        LabeledContent {
            Text(UserPublicID.formatDisplay(UserPublicID.code(for: profile.id)))
        } label: {
            BuddyDetailFieldLabel(title: "UID", systemImage: "number")
        }
            .textSelection(.enabled)
        if PrivacyPreferences.showOnline || !profile.lastActiveText.isEmpty {
            if let status = PrivacyPreferences.statusLine(
                isOnline: false,
                lastActiveText: profile.lastActiveText
            ) {
                LabeledContent {
                    Text(status)
                } label: {
                    BuddyDetailFieldLabel(title: BuddyDetailCopy.activeLabel, systemImage: "clock")
                }
            }
        }
        LabeledContent {
            Text(profile.availability)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.availabilityLabel, systemImage: "calendar")
        }
    }
}

struct BuddyDetailServiceInfoSection: View {
    let companion: PaidCompanion

    var body: some View {
        LabeledContent {
            Text(companion.serviceType.rawValue)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.serviceTypeLabel, systemImage: "square.stack.3d.up")
        }
        LabeledContent {
            Text(companion.specialty)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.specialtyLabel, systemImage: "sparkles")
        }
        LabeledContent {
            Text(companion.priceText)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.priceLabel, systemImage: "tag")
        }
        LabeledContent {
            Text(companion.profile.availability)
        } label: {
            BuddyDetailFieldLabel(
                title: companion.isAvailable ? BuddyDetailCopy.available : BuddyDetailCopy.unavailable,
                systemImage: "calendar.badge.clock"
            )
        }
    }
}

struct BuddyDetailPerformanceSection: View {
    let companion: PaidCompanion

    private var reviewStats: PlatformReviewStats {
        PlatformReviewsStore.stats(for: .companion(companion.id))
    }

    private var rating: String {
        if let average = reviewStats.averageRating {
            return String(format: "%.1f", average)
        }
        return String(format: "%.1f", PlatformReviewCatalog.displayRating(for: companion))
    }

    private var positiveRate: String {
        guard reviewStats.total > 0 else { return "98%" }
        let value = Int((Double(reviewStats.positive) / Double(reviewStats.total) * 100).rounded())
        return "\(value)%"
    }

    var body: some View {
        LabeledContent {
            Text(BuddyDetailCopy.ordersValue(companion.orderCount))
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statOrders, systemImage: "checkmark.rectangle")
        }
        LabeledContent {
            Text(rating)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statRating, systemImage: "star.leadinghalf.filled")
        }
        LabeledContent {
            Text(positiveRate)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statPositiveRate, systemImage: "hand.thumbsup")
        }
        LabeledContent {
            Text(companion.responseTime)
        } label: {
            BuddyDetailFieldLabel(title: BuddyDetailCopy.statResponse, systemImage: "bolt.badge.clock")
        }
    }
}

// MARK: - Match / schedule / related

struct BuddyDetailMatchSection: View {
    let profile: BuddyProfile

    private var shared: [String] { BuddyMatchScorer.sharedHobbies(with: profile) }

    var body: some View {
        if shared.isEmpty {
            Text(BuddyMatchScorer.reason(for: profile))
        } else {
            TagFlow(tags: shared)
            Text(BuddyMatchScorer.reason(for: profile))
        }
    }

    var sectionTitle: String {
        shared.isEmpty ? BuddyDetailCopy.reasonTitle : BuddyDetailCopy.matchTitle
    }
}

struct BuddyDetailScheduleSection: View {
    let slots: [String]
    var allowsBooking = false
    var scheduleHint: String? = nil
    var onSelectBookableDay: ((Date) -> Void)? = nil

    @State private var selectedDay: Date?

    var body: some View {
        if slots.isEmpty {
            Text(BuddyDetailCopy.scheduleEmpty)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            BuddyScheduleCalendarView(
                slots: slots,
                selectedDay: Binding(
                    get: { selectedDay },
                    set: { day in
                        selectedDay = day
                        if let day, allowsBooking {
                            onSelectBookableDay?(day)
                        }
                    }
                ),
                allowsSelection: allowsBooking,
                showsMonthPager: true
            )
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)

            if allowsBooking {
                Text(scheduleHint ?? BuddyDetailCopy.scheduleCalendarHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct BuddyDetailCircleRow: View {
    let circleName: String
    let topic: String
    var profileSource: BuddyProfileSource = .discover

    @Environment(\.dismiss) private var dismiss
    @Environment(\.circleBrowseSheetDismiss) private var dismissMemberSheet

    private var circle: InterestCircle? {
        SampleData.circle(named: circleName)
    }

    /// 从圈子信息进入时，栈下已有圈子页 —— 官方做法是用 dismiss 回退，而非再 push
    private var shouldReturnToCircle: Bool {
        profileSource.isCircleSource(named: circleName)
    }

    var body: some View {
        if shouldReturnToCircle, circle != nil {
            Button(action: returnToCircle) {
                circleLabel
            }
            .accessibilityHint(BuddyDetailCopy.returnToCircleHint)
        } else if let circle {
            NavigationLink(value: CircleBrowseRoute.circle(circle)) {
                circleLabel
            }
            .accessibilityHint(BuddyDetailCopy.openCircleHint)
        } else {
            circleLabel
        }
    }

    private func returnToCircle() {
        if let dismissMemberSheet {
            dismissMemberSheet()
            return
        }
        dismiss()
    }

    private var circleLabel: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                Text(circleName)
                    .font(.body)
                Text(topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: circle?.systemImage ?? "person.3")
                .foregroundStyle(.tint)
        }
    }
}

/// 从圈子 / 工会 / 语音厅进入时的来源说明行
struct BuddyDetailSourceRow: View {
    let line: String
    var source: BuddyProfileSource

    private var systemImage: String {
        switch source {
        case .discover: "sparkles"
        case .circle: "person.3"
        case .guild: "building.2"
        case .voiceHall: "dot.radiowaves.left.and.right"
        }
    }

    var body: some View {
        Label {
            Text(line)
                .font(.body)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
        }
        .accessibilityElement(children: .combine)
    }
}
