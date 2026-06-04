// Module: SparkLikes — Structured analytics signposts (no PII).

import Foundation
import os
import SparkCore

public enum LikesTelemetry {
    private static let logger = Logger(subsystem: SparkLog.subsystem, category: "LikesAnalytics")

    public static func matchSheetShown() {
        logger.info("likes_match_sheet_shown")
    }

    public static func firstMessageSent(source: String) {
        logger.info("likes_first_message_sent source=\(source, privacy: .public)")
    }

    public static func inboundOpened(count: Int) {
        logger.info("likes_inbound_opened count=\(count, privacy: .public)")
    }

    public static func rewindUsed() {
        logger.info("likes_rewind_used")
    }
}
