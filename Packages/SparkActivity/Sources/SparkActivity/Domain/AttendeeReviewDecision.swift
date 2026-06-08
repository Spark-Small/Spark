// Module: SparkActivity — Host approve/reject for pending attendees.

import Foundation

/// `decision` field for `POST .../attendees/{id}/review`.
public enum AttendeeReviewDecision: String, Sendable, Equatable {
    case approve
    case reject
}
