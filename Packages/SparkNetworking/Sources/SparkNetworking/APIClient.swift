// Module: SparkNetworking — Typed JSON API built on HTTPClient.

import Foundation
import SparkCore

public struct APIClient: Sendable {
    private let http: HTTPClient
    private let decoder: JSONDecoder

    public init(http: HTTPClient, decoder: JSONDecoder = JSONDecoder()) {
        self.http = http
        self.decoder = decoder
    }

    public func get<T: Decodable & Sendable>(
        _ path: String,
        as type: T.Type = T.self
    ) async throws -> T {
        let response = try await http.execute(HTTPRequest(path: path, method: .get))
        return try decode(response.data, as: type)
    }

    public func post<T: Decodable & Sendable>(
        _ path: String,
        body: Data? = nil,
        as type: T.Type = T.self
    ) async throws -> T {
        let response = try await http.execute(HTTPRequest(path: path, method: .post, body: body))
        return try decode(response.data, as: type)
    }

    public func post(_ path: String, body: Data? = nil) async throws {
        _ = try await http.execute(HTTPRequest(path: path, method: .post, body: body))
    }

    public func patch<T: Decodable & Sendable>(
        _ path: String,
        body: Data? = nil,
        as type: T.Type = T.self
    ) async throws -> T {
        let response = try await http.execute(HTTPRequest(path: path, method: .patch, body: body))
        return try decode(response.data, as: type)
    }

    private func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        guard !data.isEmpty else {
            throw AppError.decodingFailed
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }
}
