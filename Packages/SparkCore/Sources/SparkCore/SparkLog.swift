// Module: SparkCore — Structured logging helpers.

import OSLog

public enum SparkLog {
    public static let subsystem = Bundle.main.bundleIdentifier ?? "com.sparksmall.spark"

    public static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
