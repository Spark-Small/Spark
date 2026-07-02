// Module: SparkCommunity — Maps API error payloads to domain errors.

import Foundation
import SparkCore

enum CommunityAPIErrorMapping {
    static func map(_ error: Error) -> CommunityError {
        if let communityError = error as? CommunityError {
            return communityError
        }
        if let appError = error as? AppError {
            if case let .server(statusCode, message) = appError,
               statusCode == 422,
               errorCode(in: message) == "content_rejected" {
                return .contentRejected
            }
            return .underlying(appError)
        }
        return .underlying(.unknown(message: error.localizedDescription))
    }

    private static func errorCode(in message: String?) -> String? {
        guard let message, let data = message.data(using: .utf8) else { return nil }
        struct ErrorBody: Decodable {
            struct Payload: Decodable {
                let code: String
            }

            let error: Payload
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.code
    }
}
