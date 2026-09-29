//
//  APIEnvelope.swift
//  CoordinateNetworking
//
//  dating-backend 统一响应：{ code, message, data, request_id }
//

import Foundation

public struct APIEnvelope<DataType: Decodable>: Decodable, Sendable where DataType: Sendable {
    public let code: Int
    public let message: String
    public let data: DataType?
    public let requestId: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
        case requestId = "request_id"
    }
}

public enum APIJSONCoding {
    /// Supports backend ISO-8601 strings and Foundation default numeric dates (tests / local encodes).
    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let interval = try? container.decode(Double.self) {
                return Date(timeIntervalSinceReferenceDate: interval)
            }
            let raw = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: raw) {
                return date
            }
            let basic = ISO8601DateFormatter()
            basic.formatOptions = [.withInternetDateTime]
            if let date = basic.date(from: raw) {
                return date
            }
            // Python isoformat may use +00:00 without fractional — already covered;
            // also accept trailing Z variants via replacing space
            let normalized = raw.replacingOccurrences(of: " ", with: "T")
            if let date = basic.date(from: normalized) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date: \(raw)"
            )
        }
        return decoder
    }

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
