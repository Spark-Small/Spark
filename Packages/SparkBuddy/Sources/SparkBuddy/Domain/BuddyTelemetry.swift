// Module: SparkBuddy — Structured analytics events. No PII in payloads.

import OSLog
import SparkCore

/// Buddy-funnel analytics events (view impressions, contact attempts, filter usage).
public enum BuddyTelemetry {
    private static let logger = SparkLog.logger(category: "BuddyAnalytics")

    /// Browse list loaded successfully.
    public static func browseImpression(itemCount: Int, serviceFilter: String, billingFilter: String) {
        logger.info(
            "buddy_browse_impression count=\(itemCount, privacy: .public) service=\(serviceFilter, privacy: .public) billing=\(billingFilter, privacy: .public)"
        )
    }

    /// User opened a listing detail.
    public static func listingDetailOpened(listingID: String) {
        logger.info("buddy_listing_detail_opened id=\(listingID, privacy: .public)")
    }

    /// User tapped "联系搭子" (contact CTA) in detail view.
    public static func contactTapped(listingID: String) {
        logger.info("buddy_contact_tapped id=\(listingID, privacy: .public)")
    }

    /// User changed billing filter chip.
    public static func billingFilterChanged(filter: String) {
        logger.info("buddy_billing_filter_changed filter=\(filter, privacy: .public)")
    }

    /// User changed service category filter chip.
    public static func serviceFilterChanged(filter: String) {
        logger.info("buddy_service_filter_changed filter=\(filter, privacy: .public)")
    }

    /// User started booking flow.
    public static func bookingStarted(listingID: String, packageID: String) {
        logger.info(
            "buddy_booking_started listing=\(listingID, privacy: .public) package=\(packageID, privacy: .public)"
        )
    }

    /// Escrow order created successfully.
    public static func bookingCompleted(orderID: String) {
        logger.info("buddy_booking_completed order=\(orderID, privacy: .public)")
    }

    /// User opened 15-minute voice pre-chat sheet.
    public static func preChatOpened(listingID: String) {
        logger.info("buddy_prechat_opened id=\(listingID, privacy: .public)")
    }

    /// User opened safety center from detail.
    public static func safetyCenterOpened(listingID: String) {
        logger.info("buddy_safety_opened id=\(listingID, privacy: .public)")
    }

    /// User opened browse options sheet (billing / sort / verified).
    public static func browseOptionsOpened(hasActiveFilters: Bool) {
        logger.info(
            "buddy_browse_options_opened active=\(hasActiveFilters, privacy: .public)"
        )
    }

    /// Profile provider hub impression.
    public static func providerHubOpened(state: String) {
        logger.info("buddy_provider_hub_opened state=\(state, privacy: .public)")
    }

    /// User opened provider application form.
    public static func providerApplicationOpened() {
        logger.info("buddy_provider_application_opened")
    }

    /// User submitted provider application.
    public static func providerApplicationSubmitted(category: String) {
        logger.info("buddy_provider_application_submitted category=\(category, privacy: .public)")
    }

    /// Approved provider opened earnings dashboard.
    public static func providerEarningsOpened() {
        logger.info("buddy_provider_earnings_opened")
    }

    /// User selected escrow payment method.
    public static func paymentMethodSelected(method: String) {
        logger.info("buddy_payment_method_selected method=\(method, privacy: .public)")
    }

    /// Escrow payment initiated.
    public static func paymentInitiated(orderID: String, method: String) {
        logger.info(
            "buddy_payment_initiated order=\(orderID, privacy: .public) method=\(method, privacy: .public)"
        )
    }

    /// Escrow payment succeeded.
    public static func paymentSucceeded(transactionID: String) {
        logger.info("buddy_payment_succeeded tx=\(transactionID, privacy: .public)")
    }

    /// Voice pre-chat session started.
    public static func preChatStarted(sessionID: String, listingID: String) {
        logger.info(
            "buddy_prechat_started session=\(sessionID, privacy: .public) listing=\(listingID, privacy: .public)"
        )
    }

    /// Voice pre-chat session ended.
    public static func preChatEnded(sessionID: String) {
        logger.info("buddy_prechat_ended session=\(sessionID, privacy: .public)")
    }

    /// AI match insight refreshed.
    public static func matchInsightRefreshed(listingID: String, matchPercent: Int) {
        logger.info(
            "buddy_match_refreshed listing=\(listingID, privacy: .public) percent=\(matchPercent, privacy: .public)"
        )
    }

    /// Safety session started for active order.
    public static func safetySessionStarted(orderID: String) {
        logger.info("buddy_safety_session_started order=\(orderID, privacy: .public)")
    }

    /// SOS triggered during companion service.
    public static func sosTriggered(sessionID: String) {
        logger.info("buddy_sos_triggered session=\(sessionID, privacy: .public)")
    }
}
