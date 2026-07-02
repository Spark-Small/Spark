// Module: SparkBuddy — API paths for companion listings and orders.

import Foundation

enum BuddyAPIPath {
    private static let buddies = "/v1/buddies"

    static func listings(
        category: String?,
        billing: String?,
        cursor: String?
    ) -> String? {
        var components = URLComponents()
        components.path = buddies
        var queryItems: [URLQueryItem] = []
        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let billing, !billing.isEmpty {
            queryItems.append(URLQueryItem(name: "billing", value: billing))
        }
        if let cursor, !cursor.isEmpty {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let path = components.string else { return nil }
        return path.hasPrefix("/") ? String(path) : "/\(path)"
    }

    static func listing(id: String) -> String? {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return "\(buddies)/\(trimmed)"
    }

    static let createOrder = "/v1/buddy-orders"
    static let providerStatus = "/v1/buddy-provider/status"
    static let providerApplication = "/v1/buddy-provider/application"
    static let providerEarnings = "/v1/buddy-provider/earnings"
    static let providerOrders = "/v1/buddy-provider/orders"
}

private extension URLComponents {
    var string: String? {
        var copy = self
        copy.scheme = nil
        copy.host = nil
        guard var path = copy.path.isEmpty ? nil : copy.path else { return nil }
        if let query = copy.percentEncodedQuery, !query.isEmpty {
            path += "?\(query)"
        }
        return path
    }
}
