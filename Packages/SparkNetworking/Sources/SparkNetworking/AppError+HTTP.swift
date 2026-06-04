// Module: SparkNetworking — Maps transport and status codes to AppError.

import Foundation
import SparkCore

enum HTTPErrorMapper {
    static func map(_ error: Error) -> AppError {
        if error is CancellationError {
            return .unknown(message: "cancelled")
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
                return .networkUnavailable
            default:
                return .unknown(message: urlError.localizedDescription)
            }
        }
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(message: error.localizedDescription)
    }

    static func map(statusCode: Int, body: Data) -> AppError {
        switch statusCode {
        case 401, 403:
            return .unauthorized
        case 400 ..< 500:
            let message = String(data: body, encoding: .utf8)
            return .server(statusCode: statusCode, message: message)
        case 500 ..< 600:
            return .server(statusCode: statusCode, message: nil)
        default:
            return .unknown(message: "Unexpected status \(statusCode)")
        }
    }
}
