// Module: SparkAuth — Authenticated session model.

import Foundation
import SparkCore

public struct AuthSession: Equatable, Sendable {
    public let userID: UserID
    public let accessToken: String

    public init(userID: UserID, accessToken: String) {
        self.userID = userID
        self.accessToken = accessToken
    }
}
