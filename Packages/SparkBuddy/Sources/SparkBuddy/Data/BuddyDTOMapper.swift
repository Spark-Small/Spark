// Module: SparkBuddy — DTO → domain mapping.

import Foundation

enum BuddyDTOMapper {
    static func listing(from dto: BuddyListingDTO) throws -> BuddyListing {
        guard let billingKind = BuddyBillingKind(apiValue: dto.billingKind) else {
            throw BuddyError.underlying(.unknown(message: dto.billingKind))
        }
        guard let serviceCategory = BuddyServiceCategory(apiValue: dto.serviceCategory) else {
            throw BuddyError.underlying(.unknown(message: dto.serviceCategory))
        }
        guard let amount = Decimal(string: dto.priceAmount) else {
            throw BuddyError.underlying(.unknown(message: dto.priceAmount))
        }
        let trimmedID = dto.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { throw BuddyError.invalidListingID }

        return BuddyListing(
            id: trimmedID,
            ownerUserID: dto.ownerUserID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? "user_\(trimmedID)",
            displayName: dto.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarURL: dto.avatarURL.flatMap(URL.init(string:)),
            coverURL: dto.coverURL.flatMap(URL.init(string:)),
            introVideoURL: dto.introVideoURL.flatMap(URL.init(string:)),
            headline: dto.headline.trimmingCharacters(in: .whitespacesAndNewlines),
            description: (dto.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            city: dto.city.trimmingCharacters(in: .whitespacesAndNewlines),
            serviceCategory: serviceCategory,
            billingKind: billingKind,
            priceAmount: amount,
            priceCurrencyCode: dto.priceCurrencyCode,
            tags: dto.tags ?? [],
            rating: dto.rating,
            reviewCount: dto.reviewCount ?? 0,
            completedOrderCount: dto.completedOrderCount ?? 0,
            isVerified: dto.isVerified ?? false,
            supportsOfflineMeetup: dto.supportsOfflineMeetup ?? true,
            supportsPaidCompanion: dto.supportsPaidCompanion ?? true,
            trust: dto.trust.map(trust(from:)),
            matchInsight: dto.matchInsight.map(matchInsight(from:)),
            packages: try (dto.packages ?? []).map(package(from:)),
            reviewSnapshot: dto.reviewSnapshot.map(reviewSnapshot(from:))
        )
    }

    static func page(from dto: BuddyListPageDTO) throws -> BuddyListPage {
        let items = try dto.items.map { try listing(from: $0) }
        return BuddyListPage(items: items, nextCursor: dto.nextCursor)
    }

    static func reviewPage(from dto: BuddyReviewPageDTO) -> BuddyReviewPage {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let items = dto.items.map { review(from: $0, formatter: formatter) }
        return BuddyReviewPage(
            items: items,
            page: dto.page,
            pageSize: dto.pageSize,
            totalCount: dto.totalCount,
            hasMore: dto.hasMore
        )
    }

    static func orderConfirmation(from dto: BuddyOrderConfirmationDTO) -> BuddyOrderConfirmation {
        BuddyOrderConfirmation(
            id: dto.id,
            listingID: dto.listingID,
            packageID: dto.packageID,
            escrowHeld: dto.escrowHeld ?? true
        )
    }

    private static func trust(from dto: BuddyTrustProfileDTO) -> BuddyTrustProfile {
        BuddyTrustProfile(
            hasIdentityVerified: dto.hasIdentityVerified ?? false,
            hasPhoneVerified: dto.hasPhoneVerified ?? false,
            hasFaceVerified: dto.hasFaceVerified ?? false,
            hasEmergencyContact: dto.hasEmergencyContact ?? false,
            authenticityScore: dto.authenticityScore,
            socialScore: dto.socialScore,
            talkativenessScore: dto.talkativenessScore,
            photographyScore: dto.photographyScore,
            localFamiliarityScore: dto.localFamiliarityScore
        )
    }

    private static func matchInsight(from dto: BuddyMatchInsightDTO) -> BuddyMatchInsight {
        BuddyMatchInsight(matchPercent: dto.matchPercent, reason: dto.reason)
    }

    private static func package(from dto: BuddyServicePackageDTO) throws -> BuddyServicePackage {
        guard let amount = Decimal(string: dto.priceAmount) else {
            throw BuddyError.underlying(.unknown(message: dto.priceAmount))
        }
        return BuddyServicePackage(
            id: dto.id,
            title: dto.title,
            durationHours: dto.durationHours,
            priceAmount: amount,
            priceCurrencyCode: dto.priceCurrencyCode,
            inclusions: dto.inclusions ?? [],
            exclusions: dto.exclusions ?? []
        )
    }

    private static func reviewSnapshot(from dto: BuddyReviewSnapshotDTO) -> BuddyReviewSnapshot {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return BuddyReviewSnapshot(
            punctuality: dto.punctuality,
            communication: dto.communication,
            expertise: dto.expertise,
            safety: dto.safety,
            fun: dto.fun,
            recommend: dto.recommend,
            reviews: (dto.reviews ?? dto.highlightReviews ?? []).map { review(from: $0, formatter: formatter) }
        )
    }

    private static func review(from dto: BuddyReviewDTO, formatter: ISO8601DateFormatter) -> BuddyReview {
        BuddyReview(
            id: dto.id,
            authorDisplayName: dto.authorDisplayName,
            rating: dto.rating,
            comment: dto.comment,
            createdAt: dto.createdAt.flatMap { formatter.date(from: $0) }
        )
    }

    static func providerStatus(from dto: BuddyProviderStatusDTO) throws -> BuddyProviderStatus {
        guard let state = BuddyProviderApprovalState(rawValue: dto.state) else {
            throw BuddyError.underlying(.unknown(message: dto.state))
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return BuddyProviderStatus(
            state: state,
            submittedAt: dto.submittedAt.flatMap { formatter.date(from: $0) },
            reviewedAt: dto.reviewedAt.flatMap { formatter.date(from: $0) },
            rejectionReason: dto.rejectionReason
        )
    }

    static func providerEarnings(from dto: BuddyProviderEarningsDTO) throws -> BuddyProviderEarnings {
        guard let available = Decimal(string: dto.availableBalance),
              let pending = Decimal(string: dto.pendingEscrow),
              let month = Decimal(string: dto.monthEarnings) else {
            throw BuddyError.underlying(.decodingFailed)
        }
        return BuddyProviderEarnings(
            availableBalance: available,
            pendingEscrow: pending,
            currencyCode: dto.currencyCode,
            completedOrderCount: dto.completedOrderCount,
            monthEarnings: month
        )
    }

    static func providerOrder(from dto: BuddyProviderOrderDTO) throws -> BuddyProviderOrder {
        guard let amount = Decimal(string: dto.amount) else {
            throw BuddyError.underlying(.decodingFailed)
        }
        guard let state = BuddyProviderOrderState(rawValue: dto.state) else {
            throw BuddyError.underlying(.unknown(message: dto.state))
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let scheduledAt = formatter.date(from: dto.scheduledAt) else {
            throw BuddyError.underlying(.decodingFailed)
        }
        return BuddyProviderOrder(
            id: dto.id,
            guestDisplayName: dto.guestDisplayName,
            packageTitle: dto.packageTitle,
            scheduledAt: scheduledAt,
            amount: amount,
            currencyCode: dto.currencyCode,
            state: state
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
