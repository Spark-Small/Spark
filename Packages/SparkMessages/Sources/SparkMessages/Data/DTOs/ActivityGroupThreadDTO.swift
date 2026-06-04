// Module: SparkMessages — Activity group thread provisioning.

import Foundation

struct EnsureActivityGroupThreadRequestDTO: Encodable, Sendable {
    let threadId: String
    let displayName: String
    let welcomeMessage: String

    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
        case displayName = "display_name"
        case welcomeMessage = "welcome_message"
    }
}
