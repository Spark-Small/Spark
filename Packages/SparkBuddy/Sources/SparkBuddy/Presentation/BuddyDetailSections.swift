// Module: SparkBuddy — Reusable detail sections (trust, match, packages, reviews, safety).

import SparkDesignSystem
import SwiftUI

// MARK: - Trust

struct BuddyTrustSection: View {
    let trust: BuddyTrustProfile

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            sectionTitle(
                String(
                    localized: "buddy.detail.trust.title",
                    defaultValue: "信任认证",
                    comment: "Trust section title"
                )
            )
            verificationGrid
            if let score = trust.authenticityScore {
                HStack {
                    Text(
                        String(
                            localized: "buddy.detail.trust.authenticity",
                            defaultValue: "真人匹配指数",
                            comment: "Authenticity score label"
                        )
                    )
                    .font(.subheadline)
                    Spacer()
                    Text("\(score)%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            personalityScores
        }
        .sparkInboxModuleSurface()
    }

    private var verificationGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: 8
        ) {
            verificationRow(
                title: String(
                    localized: "buddy.trust.identity",
                    defaultValue: "身份证",
                    comment: "Identity verification"
                ),
                isOn: trust.hasIdentityVerified
            )
            verificationRow(
                title: String(
                    localized: "buddy.trust.phone",
                    defaultValue: "手机号",
                    comment: "Phone verification"
                ),
                isOn: trust.hasPhoneVerified
            )
            verificationRow(
                title: String(
                    localized: "buddy.trust.face",
                    defaultValue: "人脸识别",
                    comment: "Face verification"
                ),
                isOn: trust.hasFaceVerified
            )
            verificationRow(
                title: String(
                    localized: "buddy.trust.emergency",
                    defaultValue: "紧急联系人",
                    comment: "Emergency contact"
                ),
                isOn: trust.hasEmergencyContact
            )
        }
    }

    @ViewBuilder
    private var personalityScores: some View {
        let rows: [(String, Int?)] = [
            (
                String(localized: "buddy.trust.social", defaultValue: "社交指数", comment: "Social score"),
                trust.socialScore
            ),
            (
                String(localized: "buddy.trust.talk", defaultValue: "健谈指数", comment: "Talk score"),
                trust.talkativenessScore
            ),
            (
                String(localized: "buddy.trust.photo", defaultValue: "摄影能力", comment: "Photo score"),
                trust.photographyScore
            ),
            (
                String(localized: "buddy.trust.local", defaultValue: "本地熟悉度", comment: "Local score"),
                trust.localFamiliarityScore
            )
        ].filter { $0.1 != nil }

        if !rows.isEmpty {
            Divider()
            ForEach(rows, id: \.0) { title, score in
                if let score {
                    scoreRow(title: title, score: score)
                }
            }
        }
    }

    private func verificationRow(title: String, isOn: Bool) -> some View {
        Label {
            Text(title)
                .font(.caption)
        } icon: {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isOn ? Color.accentColor : .secondary)
        }
        .labelStyle(.titleAndIcon)
    }

    private func scoreRow(title: String, score: Int) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(score)")
                .font(.caption.weight(.semibold))
        }
    }
}

// MARK: - Match

struct BuddyMatchSection: View {
    let insight: BuddyMatchInsight
    var onRefresh: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle(
                    String(
                        localized: "buddy.detail.match.title",
                        defaultValue: "AI 兴趣匹配",
                        comment: "Match section title"
                    )
                )
                Spacer()
                if let onRefresh {
                    Button(
                        String(localized: "buddy.detail.match.refresh", defaultValue: "刷新", comment: "Refresh match"),
                        action: onRefresh
                    )
                    .font(.caption.weight(.semibold))
                }
            }
            Text(BuddyFormatting.matchLine(insight))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(insight.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .sparkInboxModuleSurface()
    }
}

// MARK: - Packages

struct BuddyPackagesSection: View {
    let packages: [BuddyServicePackage]
    @Binding var selectedPackageID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            sectionTitle(
                String(
                    localized: "buddy.detail.packages.title",
                    defaultValue: "标准套餐",
                    comment: "Packages section title"
                )
            )
            Text(
                String(
                    localized: "buddy.detail.packages.subtitle",
                    defaultValue: "平台托管付款，禁止私下加价与隐形消费。",
                    comment: "Packages escrow note"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            ForEach(packages) { package in
                packageCard(package)
            }
        }
    }

    private func packageCard(_ package: BuddyServicePackage) -> some View {
        let isSelected = selectedPackageID == package.id
        return Button {
            selectedPackageID = package.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(package.title)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text(
                        BuddyFormatting.packagePriceLine(
                            amount: package.priceAmount,
                            currencyCode: package.priceCurrencyCode
                        )
                    )
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                }
                Text(
                    String(
                        format: String(
                            localized: "buddy.package.duration.format",
                            defaultValue: "%lld 小时",
                            comment: "Package duration hours"
                        ),
                        locale: .current,
                        package.durationHours
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                if !package.inclusions.isEmpty {
                    bulletGroup(
                        title: String(
                            localized: "buddy.package.inclusions",
                            defaultValue: "包含",
                            comment: "Inclusions label"
                        ),
                        items: package.inclusions
                    )
                }
                if !package.exclusions.isEmpty {
                    bulletGroup(
                        title: String(
                            localized: "buddy.package.exclusions",
                            defaultValue: "不包含",
                            comment: "Exclusions label"
                        ),
                        items: package.exclusions
                    )
                }
            }
            .padding(SparkLayoutMetrics.compactVerticalPadding + 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle.sparkCard)
            .overlay {
                if isSelected {
                    RoundedRectangle.sparkCard
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.sparkPressable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func bulletGroup(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "checkmark")
                    .font(.caption2)
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}

// MARK: - Reviews

struct BuddyReviewSection: View {
    let listingID: String
    let rating: Double?
    let reviewCount: Int
    let snapshot: BuddyReviewSnapshot?
    let makeReviewListViewModel: () -> BuddyReviewListViewModel
    @State private var showAllReviews = false

    private var hasSummary: Bool {
        rating != nil && reviewCount > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
            sectionTitle(
                String(
                    localized: "buddy.detail.reviews.title",
                    defaultValue: "评分与评价",
                    comment: "Reviews section title"
                )
            )

            if hasSummary, let rating {
                BuddyRatingSummaryHeader(
                    rating: rating,
                    reviewCount: reviewCount,
                    recommendScore: snapshot?.recommend
                )
            }

            if let snapshot {
                BuddyReviewDimensionBars(rows: snapshot.dimensionRows)

                if !snapshot.highlightReviews.isEmpty {
                    BuddyReviewHighlightList(reviews: snapshot.highlightReviews)
                }

                if reviewCount > snapshot.highlightReviews.count {
                    Button {
                        showAllReviews = true
                    } label: {
                        Text(
                            String(
                                format: String(
                                    localized: "buddy.reviews.viewAll.format",
                                    defaultValue: "查看全部 %lld 条评价",
                                    comment: "View all reviews CTA"
                                ),
                                locale: .current,
                                reviewCount
                            )
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .sparkMinimumTouchTarget()
                }
            }
        }
        .sparkInboxModuleSurface()
        .sheet(isPresented: $showAllReviews) {
            BuddyReviewListSheet(viewModel: makeReviewListViewModel())
        }
    }
}

// MARK: - Contact actions (pre-chat / platform chat)

struct BuddyDetailContactActionsRow: View {
    let listingID: String
    let ownerUserID: String
    var showsVoicePreChat: Bool = false
    let onPreChat: () -> Void
    let onOpenMessages: ((String) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            if showsVoicePreChat {
                Button(action: onPreChat) {
                    Label(
                        String(
                            localized: "buddy.detail.prechat",
                            defaultValue: "语音预聊",
                            comment: "Pre-chat CTA"
                        ),
                        systemImage: "phone.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                }
                .buttonStyle(.bordered)
                .sparkMinimumTouchTarget()
            }

            if let onOpenMessages {
                Button {
                    BuddyTelemetry.contactTapped(listingID: listingID)
                    onOpenMessages(ownerUserID)
                } label: {
                    Label(
                        String(
                            localized: "buddy.detail.contact",
                            defaultValue: "平台聊天",
                            comment: "Contact buddy CTA"
                        ),
                        systemImage: "message.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                }
                .buttonStyle(.bordered)
                .sparkMinimumTouchTarget()
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Safety teaser

struct BuddySafetyTeaserSection: View {
    let onOpenSafetyCenter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(
                String(
                    localized: "buddy.detail.safety.title",
                    defaultValue: "安全护航",
                    comment: "Safety section title"
                )
            )
            Label(
                String(
                    localized: "buddy.safety.location",
                    defaultValue: "服务开始自动开启实时定位共享",
                    comment: "Live location feature"
                ),
                systemImage: "location.fill"
            )
            Label(
                String(
                    localized: "buddy.safety.sos",
                    defaultValue: "一键 SOS 同步订单信息与紧急联系人",
                    comment: "SOS feature"
                ),
                systemImage: "sos"
            )
            Label(
                String(
                    localized: "buddy.safety.route",
                    defaultValue: "行程路线自动记录，风险商户预警",
                    comment: "Route monitoring"
                ),
                systemImage: "map.fill"
            )
            Button(action: onOpenSafetyCenter) {
                Text(
                    String(
                        localized: "buddy.safety.learnMore",
                        defaultValue: "了解安全机制",
                        comment: "Open safety center"
                    )
                )
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .sparkMinimumTouchTarget()
        }
        .font(.caption)
        .labelStyle(.titleAndIcon)
        .sparkInboxModuleSurface()
    }
}

// MARK: - Helpers

private func sectionTitle(_ text: String) -> some View {
    Text(text)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
}
