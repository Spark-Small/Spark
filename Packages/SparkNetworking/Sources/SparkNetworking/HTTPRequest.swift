// Module: SparkNetworking — Outbound HTTP request model.

import Foundation

public struct HTTPRequest: Sendable, Equatable {
    public let path: String
    public let method: HTTPMethod
    public var headers: [String: String]
    public var body: Data?

    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
    }
}
