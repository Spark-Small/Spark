// Module: Spark App — SwiftUI environment for messages repository.

import SparkMessages
import SwiftUI

/// Type-erased `MessagesRepository` for `@Environment` (existential `EnvironmentKey`).
public struct MessagesRepositoryBox: @unchecked Sendable {
    // REASONING: Environment values must be Sendable; repository existential is only used on MainActor.
    public let repository: any MessagesRepository

    public init(_ repository: any MessagesRepository) {
        self.repository = repository
    }
}

private struct MessagesRepositoryEnvironmentKey: EnvironmentKey {
    static let defaultValue = MessagesRepositoryBox(MockMessagesRepository())
}

public extension EnvironmentValues {
    var messagesRepositoryBox: MessagesRepositoryBox {
        get { self[MessagesRepositoryEnvironmentKey.self] }
        set { self[MessagesRepositoryEnvironmentKey.self] = newValue }
    }
}
