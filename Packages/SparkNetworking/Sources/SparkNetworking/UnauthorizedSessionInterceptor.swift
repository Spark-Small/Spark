// Module: SparkNetworking — Clears client session on authenticated 401 responses.

import Foundation
import SparkCore

/// Invokes `invalidator` when a request that carried a bearer token receives `401`.
public struct UnauthorizedSessionInterceptor: HTTPInterceptor, Sendable {
    private let invalidator: any AuthSessionInvalidating

    public init(invalidator: any AuthSessionInvalidating) {
        self.invalidator = invalidator
    }

    public func prepare(_ request: HTTPRequest) async throws -> HTTPRequest {
        request
    }

    public func process(response: HTTPResponse, for request: HTTPRequest) async throws -> HTTPResponse {
        if response.statusCode == 401, request.headers["Authorization"] != nil {
            await invalidator.sessionDidBecomeUnauthorized()
        }
        return response
    }
}
