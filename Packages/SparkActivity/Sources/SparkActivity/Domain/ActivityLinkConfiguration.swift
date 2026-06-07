// Module: SparkActivity — Share / Universal Link base (Phase 17).

import Foundation

public enum ActivityLinkConfiguration {
    /// HTTPS host for Universal Links (`https://spark.app/a/{id}`).
    public static let webBaseURL: URL = {
        guard let url = URL(string: "https://spark.app") else {
            preconditionFailure("Invalid ActivityLinkConfiguration web base")
        }
        return url
    }()

    /// When true, share sheets and copy text prefer HTTPS links.
    public static let prefersUniversalLinks = true
}
