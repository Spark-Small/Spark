// Module: SparkBuddy — Listing detail presentation.

import SparkDesignSystem
import SparkPayments
import SwiftUI

public struct BuddyDetailView: View {
    @State private var viewModel: BuddyDetailViewModel
    private let makeReviewListViewModel: ((String, Int) -> BuddyReviewListViewModel)?
    private let onOpenMessages: ((String) -> Void)?
    private let fetchRecommendedActivity: (() async -> (id: String, title: String)?)?
    private let onOpenActivity: ((String) -> Void)?

    public init(
        viewModel: BuddyDetailViewModel,
        makeReviewListViewModel: ((String, Int) -> BuddyReviewListViewModel)? = nil,
        onOpenMessages: ((String) -> Void)? = nil,
        fetchRecommendedActivity: (() async -> (id: String, title: String)?)? = nil,
        onOpenActivity: ((String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeReviewListViewModel = makeReviewListViewModel
        self.onOpenMessages = onOpenMessages
        self.fetchRecommendedActivity = fetchRecommendedActivity
        self.onOpenActivity = onOpenActivity
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "buddy.detail.loading.a11y",
                            defaultValue: "正在加载搭子详情",
                            comment: "Buddy detail loading"
                        )
                    )
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "buddy.detail.error.title",
                        defaultValue: "无法加载",
                        comment: "Buddy detail error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.load() }
                }
            case .loaded(let listing):
                detailContent(listing)
            }
        }
        .task { await viewModel.load() }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailContent(_ listing: BuddyListing) -> some View {
        @Bindable var vm = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                coverSection(listing)
                identitySection(listing)
                if let insight = viewModel.matchInsight(for: listing) {
                    BuddyMatchSection(insight: insight) {
                        Task { await viewModel.refreshMatchInsight() }
                    }
                }
                if let trust = listing.trust {
                    BuddyTrustSection(trust: trust)
                }
                if listing.reviewCount > 0 || listing.reviewSnapshot != nil {
                    BuddyReviewSection(
                        listingID: listing.id,
                        rating: listing.rating,
                        reviewCount: listing.reviewCount,
                        snapshot: listing.reviewSnapshot,
                        makeReviewListViewModel: {
                            if let makeReviewListViewModel {
                                return makeReviewListViewModel(listing.id, listing.reviewCount)
                            }
                            return BuddyReviewListViewModel(
                                listingID: listing.id,
                                reviewCount: listing.reviewCount,
                                fetchReviews: FetchBuddyReviewsUseCase(repository: MockBuddyRepository())
                            )
                        }
                    )
                }
                serviceSection(listing)
                if !listing.packages.isEmpty {
                    BuddyPackagesSection(
                        packages: listing.packages,
                        selectedPackageID: $vm.selectedPackageID
                    )
                } else {
                    pricingSection(listing)
                }
                if !listing.description.isEmpty {
                    descriptionSection(listing)
                }
                if !listing.tags.isEmpty {
                    tagsSection(listing)
                }
                if let fetchRecommendedActivity, let onOpenActivity {
                    BuddyRelatedActivitySection(
                        fetchRecommendedActivity: fetchRecommendedActivity,
                        onOpenActivity: onOpenActivity
                    )
                }
                BuddySafetyTeaserSection {
                    viewModel.presentSafetyCenter()
                }
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.bottom, SparkLayoutMetrics.sectionVerticalPadding * 3)
        }
        .sparkFeedModuleScroll()
        .navigationTitle(listing.displayName)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar(listing)
        }
        .sheet(isPresented: $vm.isBookingSheetPresented) {
            BuddyBookingSheet(viewModel: vm, listing: listing)
        }
        .sheet(isPresented: $vm.isPreChatSheetPresented) {
            BuddyPreChatSheet(viewModel: vm, listing: listing)
        }
        .navigationDestination(isPresented: $vm.isSafetyCenterPresented) {
            BuddySafetyCenterView(
                listingID: listing.id,
                isSessionActive: viewModel.activeSafetySession != nil
            ) {
                Task { await viewModel.triggerSOSAlert() }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func coverSection(_ listing: BuddyListing) -> some View {
        if let url = listing.coverURL {
            SparkCachedRemoteImage(
                url: url,
                content: { image in
                    image.resizable().scaledToFill()
                },
                placeholder: {
                    Rectangle().fill(Color(.tertiarySystemFill))
                }
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle.sparkCard)
            .sparkPhotoTextScrim()
        }
    }

    private func identitySection(_ listing: BuddyListing) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(listing.displayName)
                    .font(.title3.weight(.semibold))
                Label(listing.serviceCategory.localizedTitle, systemImage: listing.serviceCategory.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                if listing.isVerified || listing.trust?.isFullyVerified == true {
                    Label(
                        String(
                            localized: "buddy.verified",
                            defaultValue: "真人认证",
                            comment: "Verified buddy"
                        ),
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .labelStyle(.titleAndIcon)
                }
            }
            Text(listing.headline)
                .font(.body)
                .foregroundStyle(.primary)
            if listing.completedOrderCount > 0 {
                Text(
                    String(
                        format: String(
                            localized: "buddy.detail.orders.format",
                            defaultValue: "已完成 %lld 单",
                            comment: "Completed orders count"
                        ),
                        locale: .current,
                        listing.completedOrderCount
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            BuddyDetailContactActionsRow(
                listingID: listing.id,
                ownerUserID: listing.ownerUserID,
                showsVoicePreChat: SparkFeatureFlags.isBuddyVoicePreChatEnabled,
                onPreChat: { viewModel.presentPreChat() },
                onOpenMessages: onOpenMessages
            )
        }
    }

    private func pricingSection(_ listing: BuddyListing) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                String(
                    localized: "buddy.detail.pricing.title",
                    defaultValue: "计费",
                    comment: "Pricing section title"
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            Text(
                BuddyFormatting.priceLine(
                    amount: listing.priceAmount,
                    currencyCode: listing.priceCurrencyCode,
                    billingKind: listing.billingKind
                )
            )
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            Text(listing.billingKind.localizedTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .sparkInboxModuleSurface()
    }

    private func serviceSection(_ listing: BuddyListing) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                String(
                    localized: "buddy.detail.service.title",
                    defaultValue: "服务类型",
                    comment: "Service section title"
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            Text(
                BuddyFormatting.serviceLine(
                    supportsPaidCompanion: listing.supportsPaidCompanion,
                    supportsOfflineMeetup: listing.supportsOfflineMeetup
                )
            )
            .font(.body)
            if !listing.city.isEmpty {
                Label(listing.city, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sparkInboxModuleSurface()
    }

    @ViewBuilder
    private func descriptionSection(_ listing: BuddyListing) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                String(
                    localized: "buddy.detail.description.title",
                    defaultValue: "简介",
                    comment: "Description section title"
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            Text(listing.description)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .sparkInboxModuleSurface()
    }

    private func tagsSection(_ listing: BuddyListing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                String(
                    localized: "buddy.detail.tags.title",
                    defaultValue: "能力标签",
                    comment: "Tags section title"
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            BuddyTagFlowRow(tags: listing.tags)
        }
    }

    private func actionBar(_ listing: BuddyListing) -> some View {
        Button {
            viewModel.presentBooking(for: listing)
        } label: {
            Text(
                String(
                    localized: "buddy.detail.book",
                    defaultValue: "立即预约",
                    comment: "Book buddy CTA"
                )
            )
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding + 2)
        }
        .buttonStyle(.borderedProminent)
        .sparkMinimumTouchTarget()
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .background(.bar)
    }
}

// MARK: - Tag flow layout

struct BuddyTagFlowRow: View {
    let tags: [String]

    var body: some View {
        // REASONING: Simple fixed-chunk layout avoids expensive custom Layout pass for short tag sets.
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunkedTags, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary, in: Capsule())
                    }
                }
            }
        }
    }

    private var chunkedTags: [[String]] {
        stride(from: 0, to: tags.count, by: 3).map {
            Array(tags[$0 ..< min($0 + 3, tags.count)])
        }
    }
}

#Preview("Buddy detail") {
    NavigationStack {
        BuddyDetailView(viewModel: BuddyPreviewFactory.detailViewModel())
    }
}

#Preview("Buddy detail — dark") {
    SparkPreviewSupport.darkMode {
        NavigationStack {
            BuddyDetailView(viewModel: BuddyPreviewFactory.detailViewModel())
        }
    }
}

#Preview("Buddy detail — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        NavigationStack {
            BuddyDetailView(viewModel: BuddyPreviewFactory.detailViewModel(listingID: "buddy_event_1"))
        }
    }
}
