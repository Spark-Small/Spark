// Module: SparkMessages — Activity invitation response payload.

import Foundation

struct InvitationRespondRequestDTO: Encodable, Sendable {
    let response: String
}
