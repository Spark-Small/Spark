// Module: SparkActivity — Discover feed join button visibility.

/// Discover tri-track policy: cover opens Today hero; info opens detail; join opens confirmation sheet.
enum ActivityBrowseJoinPolicy {
    /// Shows the feed join chip when the viewer can still register from discover browse.
    static func showsJoinButton(for item: ActivityItem) -> Bool {
        guard item.lifecycleStatus == .scheduled else { return false }
        switch item.rsvpStatus {
        case .invited, .declined:
            return !item.isAtCapacity
        case .going, .maybe, .waitlisted, .host:
            return false
        }
    }
}
