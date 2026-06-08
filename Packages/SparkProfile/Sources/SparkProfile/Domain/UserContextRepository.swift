// Module: SparkProfile — User relationship context boundary.

import Foundation

public protocol UserContextRepository: Sendable {
    func fetchContext(userID: String) async throws -> UserContext
}
