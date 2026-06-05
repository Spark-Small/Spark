// Module: SparkNetworking — Runtime API base URL and environment flags.

import Foundation

/// API environment loaded from the app bundle (`SPARKAPIBaseURL` build setting).
public struct APIConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let usesMockBackend: Bool

    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.usesMockBackend = baseURL.host?.contains("mock.spark.local") == true
    }

    /// Reads `SPARKAPIBaseURL` from the app Info.plist (injected via `Config/Spark.xcconfig`) with a safe default.
    public static func loadFromBundle(_ bundle: Bundle = .main) -> APIConfiguration {
        let raw = bundle.object(forInfoDictionaryKey: "SPARKAPIBaseURL") as? String
        let urlString: String
        if let raw, !raw.isEmpty {
            urlString = raw
        } else {
            urlString = "https://mock.spark.local"
        }
        guard let url = URL(string: urlString) else {
            guard let fallback = URL(string: "https://mock.spark.local") else {
                preconditionFailure("Invalid default API base URL")
            }
            return APIConfiguration(baseURL: fallback)
        }
        return APIConfiguration(baseURL: url)
    }
}
