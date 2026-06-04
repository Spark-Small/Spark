// Module: SparkNetworking — Request/response mutation pipeline.

import Foundation
import SparkCore

public protocol HTTPInterceptor: Sendable {
    func prepare(_ request: HTTPRequest) async throws -> HTTPRequest
    func process(response: HTTPResponse, for request: HTTPRequest) async throws -> HTTPResponse
}

public struct AuthorizationInterceptor: HTTPInterceptor, Sendable {
    private let tokenProvider: any AccessTokenProviding

    public init(tokenProvider: any AccessTokenProviding) {
        self.tokenProvider = tokenProvider
    }

    public func prepare(_ request: HTTPRequest) async throws -> HTTPRequest {
        var updated = request
        if let token = await tokenProvider.accessToken(), !token.isEmpty {
            updated.headers["Authorization"] = "Bearer \(token)"
        }
        return updated
    }

    public func process(response: HTTPResponse, for request: HTTPRequest) async throws -> HTTPResponse {
        response
    }
}
