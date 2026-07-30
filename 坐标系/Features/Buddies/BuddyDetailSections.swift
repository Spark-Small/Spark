//
//  BuddyDetailSections.swift
//  坐标系
//
//  搭子详情 Form 分区：对齐活动详情字阶 / 行结构；补全交友向资料展示。
//

import SwiftUI

// MARK: - Trust

struct BuddyDetailTrust {
    var name: String
    var isVerified: Bool
    var badgeTitle: String?
    var metricsLine: String
    var chatAccessibility: String

    static func make(free buddy: CircleBuddy) -> BuddyDetailTrust {
        let avg = averageRating(buddy.reviews)
        let ratingPart = avg.map { String(format: "★ %.1f", $0) } ?? "暂无评分"
        return BuddyDetailTrust(
            name: buddy.profile.nickname,
            isVerified: false,
            badgeTitle: buddy.circleName,
            metricsLine: "\(ratingPart) · \(BuddyDetailCopy.reviewCount(buddy.reviews.count)) · \(buddy.topic)",
            chatAccessibility: BuddyDetailCopy.greetAccessibility(nickname: buddy.profile.nickname)
        )
    }

    static func make(paid companion: PaidCompanion) -> BuddyDetailTrust {
        BuddyDetailTrust(
            name: companion.profile.nickname,
            isVerified: companion.isVerified,
            badgeTitle: companion.serviceType.rawValue,
            metricsLine: "★ \(BuddyDetailCopy.ratingValue(companion.rating)) · \(BuddyDetailCopy.ordersValue(companion.orderCount)) · \(companion.responseTime)",
            chatAccessibility: BuddyDetailCopy.greetAccessibility(nickname: companion.profile.nickname)
        )
    }

    private static func averageRating(_ reviews: [BuddyReview]) -> Double? {
        guard !reviews.isEmpty else { return nil }
        let sum = reviews.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(reviews.count)
    }
}

struct BuddyDetailTrustRow: View {
    let trust: BuddyDetailTrust
    var onProfile: () -> Void
    var onChat: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button(action: onProfile) {
                HStack(alignment: .center) {
                    PlatformListAvatarView(name: trust.name)
                    VStack(alignment: .leading) {
                        nameBadgesRow
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
                accessibilityLabel: trust.chatAccessibility,
                action: onChat
            )
        }
    }

    private var nameBadgesRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(trust.name)
            if trust.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel(BuddyDetailCopy.verifiedBadge)
            }
            if let badgeTitle = trust.badgeTitle {
                Text(badgeTitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .font(.body)
        .lineLimit(1)
    }

    private var accessibilitySummary: String {
        [trust.name, trust.badgeTitle, trust.metricsLine]
            .compactMap { $0 }
            .joined(separator: "，")
    }
}

// MARK: - Hero

struct BuddyDetailHeroGallery: View {
    let profile: BuddyProfile
    var verifiedBadge: Bool = false

    @State private var selectedIndex = 0
    @State private var showViewer = false

    private var photos: [CommunityPhotoRef] { profile.photoRefs }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .bottomTrailing) {
                photoLayer
                    .onTapGesture {
                        guard !photos.isEmpty else { return }
                        showViewer = true
                    }

                if photos.count > 1 {
                    Button {
                        showViewer = true
                    } label: {
                        Label(BuddyDetailCopy.photosCount(photos.count), systemImage: "photo.on.rectangle.angled")
                    }
                    .labelStyle(.titleAndIcon)
                    .activityGlassChip()
                    .platformMediaChromeInset()
                }
            }

            if verifiedBadge {
                PlatformMediaCaptionBadge(title: BuddyDetailCopy.verifiedBadge, tint: .accentColor)
            }
        }
        .aspectRatio(PlatformMetrics.detailHeroAspectRatio, contentMode: .fit)
        .clipShape(PlatformMetrics.cardShape)
        .fullScreenCover(isPresented: $showViewer) {
            CommunityPhotoViewer(photos: photos, startIndex: selectedIndex)
        }
        .accessibilityLabel("\(profile.nickname)的照片")
    }

    @ViewBuilder
    private var photoLayer: some View {
        if photos.count > 1 {
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, ref in
                    CommunityRemotePhoto(ref: ref)
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        } else if let first = photos.first {
            CommunityRemotePhoto(ref: first)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            CommunityRemotePhoto(ref: .seeded(seed: abs(profile.id.hashValue % 9000) + 100, symbol: "person.fill"))
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
    }
}

// MARK: - Identity

struct BuddyDetailIdentitySection: View {
    let profile: BuddyProfile
    var pitch: String
    var statusLine: String?
    var metricsFooter: String?
    var statusTint: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
            HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.detailMicroSpacing) {
                Text(profile.nickname)
                    .font(.title2.weight(.bold))
                Text(profile.gender.symbol)
                    .font(.body)
                    .foregroundStyle(profile.gender.tint)
                if let statusLine {
                    Text(statusLine)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusTint)
                }
            }

            Text(pitch)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(statusMetaLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let metricsFooter {
                Text(metricsFooter)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            if !profile.tags.isEmpty {
                TagFlow(tags: profile.tags)
            }
        }
    }

    private var statusMetaLine: String {
        [
            profile.city,
            profile.distanceText,
            profile.lastActiveText,
            profile.availability
        ].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

// MARK: - Basic info

struct BuddyDetailBasicInfoSection: View {
    let profile: BuddyProfile

    var body: some View {
        LabeledContent(BuddyDetailCopy.genderLabel, value: profile.gender.rawValue)
        LabeledContent(BuddyDetailCopy.ageLabel, value: BuddyDetailCopy.ageValue(profile.age))
        LabeledContent(BuddyDetailCopy.heightLabel, value: profile.heightText)
        LabeledContent(BuddyDetailCopy.weightLabel, value: profile.weightText)
        LabeledContent(BuddyDetailCopy.cityLabel, value: profile.city)
        LabeledContent(BuddyDetailCopy.distanceLabel, value: profile.distanceText)
        LabeledContent(BuddyDetailCopy.activeLabel, value: profile.lastActiveText)
        LabeledContent(BuddyDetailCopy.availabilityLabel, value: profile.availability)
        LabeledContent(BuddyDetailCopy.lookingLabel, value: profile.lookingFor)
    }
}

struct BuddyDetailServiceInfoSection: View {
    let companion: PaidCompanion

    var body: some View {
        LabeledContent(BuddyDetailCopy.serviceTypeLabel, value: companion.serviceType.rawValue)
        LabeledContent(BuddyDetailCopy.specialtyLabel, value: companion.specialty)
        LabeledContent(BuddyDetailCopy.priceLabel, value: companion.priceText)
        LabeledContent(BuddyDetailCopy.ratingLabel, value: BuddyDetailCopy.ratingValue(companion.rating))
        LabeledContent(BuddyDetailCopy.ordersLabel, value: BuddyDetailCopy.ordersValue(companion.orderCount))
        LabeledContent(BuddyDetailCopy.responseLabel, value: companion.responseTime)
        LabeledContent(
            companion.isAvailable ? BuddyDetailCopy.available : BuddyDetailCopy.unavailable,
            value: companion.profile.availability
        )
    }
}

// MARK: - Match / schedule / reviews / related

struct BuddyDetailMatchSection: View {
    let profile: BuddyProfile

    private var shared: [String] { BuddyMatchScorer.sharedHobbies(with: profile) }

    var body: some View {
        if shared.isEmpty {
            Text(BuddyMatchScorer.reason(for: profile))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            TagFlow(tags: shared)
            Text(BuddyMatchScorer.reason(for: profile))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var sectionTitle: String {
        shared.isEmpty ? BuddyDetailCopy.reasonTitle : BuddyDetailCopy.matchTitle
    }
}

struct BuddyDetailScheduleSection: View {
    let slots: [String]

    var body: some View {
        if slots.isEmpty {
            Text(BuddyDetailCopy.scheduleEmpty)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            ForEach(slots, id: \.self) { slot in
                Label(slot, systemImage: "clock")
                    .font(.body)
            }
        }
    }
}

struct BuddyDetailReviewsSection: View {
    let reviews: [BuddyReview]

    var body: some View {
        if reviews.isEmpty {
            Text(BuddyDetailCopy.reviewsEmpty)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            ForEach(reviews) { review in
                BuddyReviewRow(review: review)
            }
        }
    }
}

struct BuddyDetailRelatedRail: View {
    let activities: [Activity]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        DiscoverHorizontalRail {
            ForEach(activities) { activity in
                NavigationLink(value: activity) {
                    relatedCard(activity)
                }
                .buttonStyle(.plain)
                .platformContinueRailFrame()
            }
        }
        .listRowInsets(relatedRailInsets)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var relatedRailInsets: EdgeInsets {
        let horizontal = PlatformMetrics.contentInset
        return EdgeInsets(
            top: PlatformMetrics.sectionHeaderSpacing,
            leading: -horizontal,
            bottom: PlatformMetrics.sectionHeaderSpacing,
            trailing: -horizontal
        )
    }

    private func relatedCard(_ activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            CommunityRemotePhoto(ref: activity.coverPhoto)
                .aspectRatio(PlatformMetrics.continueCardAspectRatio, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(PlatformMetrics.posterShape)
                .overlay(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                        Text(activity.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        Text(Formatters.activityEventTime(from: activity.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(PlatformMetrics.captionBadgeInset)
                    .colorScheme(.dark)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.title)，\(Formatters.activityEventTime(from: activity.date))")
    }
}

struct BuddyDetailCircleRow: View {
    let circleName: String
    let topic: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                Text(circleName)
                    .font(.body)
                Text(topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "person.3")
                .foregroundStyle(.tint)
        }
    }
}

/// 从组织 / 工会 / 语音厅进入时的来源说明行
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
