// Module: SparkCore — Retry configuration for HTTP and background tasks.

import Foundation

/// Describes exponential backoff retry behavior used by `HTTPClient`.
public struct RetryPolicy: Sendable, Equatable {
    public let maxAttempts: Int
    public let baseDelaySeconds: TimeInterval
    public let multiplier: Double

    public init(maxAttempts: Int = 3, baseDelaySeconds: TimeInterval = 0.5, multiplier: Double = 2.0) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelaySeconds = baseDelaySeconds
        self.multiplier = multiplier
    }

    public static let `default` = RetryPolicy()

    /// Delay before attempt index (0-based), capped for sanity.
    public func delayBeforeAttempt(_ attemptIndex: Int) -> TimeInterval {
        guard attemptIndex > 0 else { return 0 }
        let exponent = Double(attemptIndex - 1)
        return min(baseDelaySeconds * pow(multiplier, exponent), 30)
    }
}
