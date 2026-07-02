// Module: SparkBuddy — Network companion listings.

import Foundation
import SparkCore
import SparkNetworking

public struct LiveBuddyRepository: BuddyRepository, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchListings(query: BuddyListQuery) async throws -> BuddyListPage {
        guard let path = BuddyAPIPath.listings(
            category: query.serviceFilter.apiCategoryValue,
            billing: query.billingFilter.apiBillingValue,
            cursor: query.cursor
        ) else {
            return BuddyListPage(items: [], nextCursor: nil)
        }
        do {
            let dto: BuddyListPageDTO = try await apiClient.get(path)
            return try BuddyDTOMapper.page(from: dto)
        } catch {
            throw BuddyError.underlying(mapToAppError(error))
        }
    }

    public func fetchListing(id: String) async throws -> BuddyListing {
        guard let path = BuddyAPIPath.listing(id: id) else {
            throw BuddyError.invalidListingID
        }
        do {
            let dto: BuddyListingDTO = try await apiClient.get(path)
            return try BuddyDTOMapper.listing(from: dto)
        } catch {
            throw BuddyError.underlying(mapToAppError(error))
        }
    }

    public func createOrder(draft: BuddyOrderDraft) async throws -> BuddyOrderConfirmation {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let body = BuddyCreateOrderRequestDTO(
            listingID: draft.listingID,
            packageID: draft.packageID,
            scheduledAt: formatter.string(from: draft.scheduledAt),
            paymentMethod: draft.paymentMethod.apiValue
        )
        do {
            let encoded = try JSONEncoder().encode(body)
            let dto: BuddyOrderConfirmationDTO = try await apiClient.post(
                BuddyAPIPath.createOrder,
                body: encoded
            )
            return BuddyDTOMapper.orderConfirmation(from: dto)
        } catch {
            throw BuddyError.underlying(mapToAppError(error))
        }
    }

    public func fetchProviderStatus() async throws -> BuddyProviderStatus {
        do {
            let dto: BuddyProviderStatusDTO = try await apiClient.get(BuddyAPIPath.providerStatus)
            return try BuddyDTOMapper.providerStatus(from: dto)
        } catch {
            throw BuddyError.underlying(mapToAppError(error))
        }
    }

    public func submitProviderApplication(_ draft: BuddyProviderApplicationDraft) async throws -> BuddyProviderStatus {
        guard draft.isValid else { throw BuddyError.invalidApplication }
        let body = BuddyProviderApplicationRequestDTO(
            displayName: draft.displayName,
            city: draft.city,
            serviceCategory: draft.serviceCategory.apiValue,
            bio: draft.bio,
            capabilityTags: draft.capabilityTags
        )
        do {
            let encoded = try JSONEncoder().encode(body)
            let dto: BuddyProviderStatusDTO = try await apiClient.post(
                BuddyAPIPath.providerApplication,
                body: encoded
            )
            return try BuddyDTOMapper.providerStatus(from: dto)
        } catch {
            throw BuddyError.underlying(mapToAppError(error))
        }
    }

    public func fetchProviderEarnings() async throws -> BuddyProviderEarnings {
        let status = try await fetchProviderStatus()
        guard status.canAccessEarnings else { throw BuddyError.providerNotApproved }
        do {
            let dto: BuddyProviderEarningsDTO = try await apiClient.get(BuddyAPIPath.providerEarnings)
            return try BuddyDTOMapper.providerEarnings(from: dto)
        } catch {
            throw BuddyError.underlying(mapToAppError(error))
        }
    }

    public func fetchProviderOrders() async throws -> [BuddyProviderOrder] {
        let status = try await fetchProviderStatus()
        guard status.canAccessEarnings else { throw BuddyError.providerNotApproved }
        do {
            let dtos: [BuddyProviderOrderDTO] = try await apiClient.get(BuddyAPIPath.providerOrders)
            return try dtos.map { try BuddyDTOMapper.providerOrder(from: $0) }
        } catch {
            throw BuddyError.underlying(mapToAppError(error))
        }
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let buddyError = error as? BuddyError,
           case let .underlying(appError) = buddyError {
            return appError
        }
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(message: error.localizedDescription)
    }
}
