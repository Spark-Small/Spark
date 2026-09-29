//
//  APIClient.swift
//  CoordinateNetworking
//

import Foundation
import Network

public protocol APITokenProviding: Sendable {
    var accessToken: String? { get }
}

public protocol APITokenRefreshing: Sendable {
    /// Return a new access token, or `nil` if refresh is impossible.
    func refreshedAccessToken() async throws -> String?
}

public struct EmptyAPITokenProvider: APITokenProviding {
    public init() {}
    public var accessToken: String? { nil }
}

/// 进程级网络可达性（`NWPathMonitor`）。
public final class APINetworkReachability: @unchecked Sendable {
    public static let shared = APINetworkReachability()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "coordinate.api.path-monitor")
    private let lock = NSLock()
    private var _isSatisfied = true

    public var isSatisfied: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isSatisfied
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.lock.lock()
            self._isSatisfied = path.status == .satisfied
            self.lock.unlock()
        }
        monitor.start(queue: queue)
    }
}

public struct APIClient: Sendable {
    public let baseURL: URL
    public let session: URLSession
    public let tokenProvider: any APITokenProviding
    public let tokenRefresher: (any APITokenRefreshing)?
    public let decoder: JSONDecoder
    public let maxTransportRetries: Int

    public static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    public init(
        baseURL: URL,
        session: URLSession = APIClient.makeDefaultSession(),
        tokenProvider: any APITokenProviding = EmptyAPITokenProvider(),
        tokenRefresher: (any APITokenRefreshing)? = nil,
        decoder: JSONDecoder = APIJSONCoding.makeDecoder(),
        maxTransportRetries: Int = 2
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        self.tokenRefresher = tokenRefresher
        self.decoder = decoder
        self.maxTransportRetries = max(0, maxTransportRetries)
    }

    public func send<Response: Decodable & Sendable>(_ endpoint: APIEndpoint<Response>) async throws -> Response {
        try await send(endpoint, allowRefresh: true)
    }

    private func send<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint<Response>,
        allowRefresh: Bool
    ) async throws -> Response {
        try Task.checkCancellation()
        guard APINetworkReachability.shared.isSatisfied else {
            throw APIError.offline
        }

        let request = try endpoint.urlRequest(
            baseURL: baseURL,
            token: tokenProvider.accessToken
        )
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await perform(request)
        } catch let api as APIError {
            throw api
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401, allowRefresh, let tokenRefresher {
            _ = try await tokenRefresher.refreshedAccessToken()
            return try await send(endpoint, allowRefresh: false)
        }

        guard (200 ... 299).contains(http.statusCode) else {
            if let envelope = try? decoder.decode(APIEnvelope<Response>.self, from: data),
               envelope.code != 0 {
                throw APIError.business(code: envelope.code, message: envelope.message)
            }
            throw APIError.httpStatus(http.statusCode)
        }
        do {
            return try decodePayload(Response.self, from: data)
        } catch let api as APIError {
            throw api
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error?
        for attempt in 0...maxTransportRetries {
            try Task.checkCancellation()
            do {
                return try await session.data(for: request)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                if attempt == maxTransportRetries { break }
                let delayMs = 250 * (attempt + 1)
                try? await Task.sleep(for: .milliseconds(delayMs))
            }
        }
        throw APIError.transport(lastError?.localizedDescription ?? "网络请求失败")
    }

    /// Prefer `{code,data}` envelope; fall back to raw body (unit tests / legacy).
    private func decodePayload<Response: Decodable & Sendable>(_ type: Response.Type, from data: Data) throws -> Response {
        if let envelope = try? decoder.decode(APIEnvelope<Response>.self, from: data) {
            guard envelope.code == 0 else {
                throw APIError.business(code: envelope.code, message: envelope.message)
            }
            guard let payload = envelope.data else {
                throw APIError.decodingFailed
            }
            return payload
        }
        return try decoder.decode(Response.self, from: data)
    }
}
