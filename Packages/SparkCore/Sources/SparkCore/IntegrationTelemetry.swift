// Module: SparkCore — Nexus integration funnel signposts (PRODUCT_INTEGRATION_PLAN §5).

import OSLog

/// Structured analytics events for cross-module conversion metrics. No PII in payloads.
public enum IntegrationTelemetry {
    private static let logger = SparkLog.logger(category: "IntegrationAnalytics")

    /// Discover browse list loaded (`browse_to_rsvp` numerator/denominator).
    public static func browseImpression(itemCount: Int) {
        logger.info("integration_browse_impression count=\(itemCount, privacy: .public)")
    }

    /// User RSVP'd from browse discover path.
    public static func browseToRSVP(activityID: String) {
        logger.info("integration_browse_to_rsvp activity_id=\(activityID, privacy: .public)")
    }

    /// Match sheet → create coffee activity intent (`match_to_rsvp_7d` proxy).
    public static func matchToActivityIntent(source: String) {
        logger.info("integration_match_to_activity_intent source=\(source, privacy: .public)")
    }

    /// Unified profile card opened from any tab (`profile_card_open_rate`).
    public static func profileCardOpened(userID: String) {
        logger.info("integration_profile_card_opened user_id=\(userID, privacy: .public)")
    }

    /// RSVP completed with entry source.
    public static func rsvpCompleted(source: String, activityID: String) {
        logger.info(
            "integration_rsvp_completed source=\(source, privacy: .public) activity_id=\(activityID, privacy: .public)"
        )
    }

    /// Group message sent within activity thread after RSVP (`rsvp_to_group_msg_24h` proxy).
    public static func groupMessageAfterRSVP(activityID: String) {
        logger.info("integration_group_msg_after_rsvp activity_id=\(activityID, privacy: .public)")
    }

    /// Post-event recap published (`activity_end_to_recap`).
    public static func activityEndToRecap(activityID: String) {
        logger.info("integration_activity_end_to_recap activity_id=\(activityID, privacy: .public)")
    }

    /// Universal link / invite opened (`invite_link_to_rsvp` denominator).
    public static func inviteLinkOpened(activityID: String) {
        logger.info("integration_invite_link_opened activity_id=\(activityID, privacy: .public)")
    }

    /// RSVP from external invite entry (`invite_link_to_rsvp` numerator).
    public static func inviteLinkToRSVP(activityID: String) {
        logger.info("integration_invite_link_to_rsvp activity_id=\(activityID, privacy: .public)")
    }
}
