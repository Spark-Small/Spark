// Module: SparkMessages — API DTO for unread counts.

import Foundation

struct MessagesUnreadDTO: Decodable, Sendable, Equatable {
    let count: Int
}

struct EmptyResponseDTO: Decodable, Sendable, Equatable {}
