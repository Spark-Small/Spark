// Module: SparkAuth — Authentication state machine.

import Foundation

public enum AuthState: Equatable, Sendable {
    case idle
    case loading
    case authenticated(AuthSession)
    case unauthenticated
    case failure(message: String)
}
