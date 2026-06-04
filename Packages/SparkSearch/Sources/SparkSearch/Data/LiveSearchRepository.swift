// Module: SparkSearch — Network search.

import Foundation
import SparkCore
import SparkNetworking

public struct LiveSearchRepository: SearchRepository, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func search(query: String) async throws -> [SearchResultItem] {
        guard let path = SearchAPIPath.search(query: query) else {
            return []
        }
        do {
            let dto: SearchResponseDTO = try await apiClient.get(path)
            return dto.results.map(SearchDTOMapper.result)
        } catch {
            throw SearchError.underlying(mapToAppError(error))
        }
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let searchError = error as? SearchError,
           case let .underlying(appError) = searchError {
            return appError
        }
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(message: error.localizedDescription)
    }
}
