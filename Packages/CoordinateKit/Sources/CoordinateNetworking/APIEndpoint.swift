//
//  APIEndpoint.swift
//  CoordinateNetworking
//

import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public struct APIEndpoint<Response: Decodable & Sendable>: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let body: Data?

    public init(path: String, method: HTTPMethod = .get, body: Data? = nil) {
        self.path = path
        self.method = method
        self.body = body
    }

    public func urlRequest(baseURL: URL, token: String?) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
