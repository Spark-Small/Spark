// Module: SparkMessages — In-memory fallback cache for unread count.

import Foundation

public actor MessagesCache {
    private var unreadCount: Int?

    public init() {}

    public func get() -> Int? { unreadCount }

    public func set(_ count: Int) {
        unreadCount = count
    }

    public func clear() {
        unreadCount = 0
    }
}
