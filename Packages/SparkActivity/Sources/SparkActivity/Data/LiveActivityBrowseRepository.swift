// Module: SparkActivity — Live browse API.

import Foundation
import os
import SparkCore
import SparkNetworking

public struct LiveActivityBrowseRepository: ActivityBrowseRepository, Sendable {
    private let apiClient: APIClient
    private let logger = Logger(subsystem: "com.spark.activity", category: "LiveActivityBrowse")

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchBrowse(query: ActivityBrowseQuery) async throws -> ActivityBrowsePage {
        do {
            let dto: ActivityBrowseResponseDTO = try await apiClient.get(ActivityAPIPath.browse(query: query))
            let items = dto.items.map(ActivityDTOMapper.item(from:))
            return ActivityBrowsePage(items: items, nextCursor: dto.nextCursor)
        } catch let error as AppError {
            logger.error("browse fetch failed: \(error.localizedDescription, privacy: .public)")
            throw ActivityError.underlying(error)
        } catch {
            logger.error("browse fetch failed: \(error.localizedDescription, privacy: .public)")
            throw ActivityError.underlying(.unknown(message: error.localizedDescription))
        }
    }
}
