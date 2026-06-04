// Module: SparkNetworking — URLSession-backed HTTP actor with retry and interceptors.

import Foundation
import SparkCore

public actor HTTPClient {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let interceptors: [any HTTPInterceptor]
    private let retryPolicy: RetryPolicy

    public init(
        configuration: APIConfiguration,
        session: URLSession = .shared,
        interceptors: [any HTTPInterceptor] = [],
        retryPolicy: RetryPolicy = .default
    ) {
        self.configuration = configuration
        self.session = session
        self.interceptors = interceptors
        self.retryPolicy = retryPolicy
    }

    public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        var lastError: Error?
        for attempt in 0 ..< retryPolicy.maxAttempts {
            if attempt > 0 {
                let delay = retryPolicy.delayBeforeAttempt(attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            do {
                return try await performOnce(request)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                guard shouldRetry(error: error, attempt: attempt) else { break }
            }
        }
        throw HTTPErrorMapper.map(lastError ?? AppError.networkUnavailable)
    }

    private func performOnce(_ request: HTTPRequest) async throws -> HTTPResponse {
        var prepared = request
        for interceptor in interceptors {
            prepared = try await interceptor.prepare(prepared)
        }

        var urlRequest = try makeURLRequest(from: prepared)
        let (data, urlResponse) = try await session.data(for: urlRequest)
        guard let http = urlResponse as? HTTPURLResponse else {
            throw AppError.unknown(message: "Invalid URL response")
        }

        var response = HTTPResponse(
            statusCode: http.statusCode,
            headers: http.allHeaderFields.reduce(into: [:]) { result, pair in
                if let key = pair.key as? String, let value = pair.value as? String {
                    result[key] = value
                }
            },
            data: data
        )

        for interceptor in interceptors {
            response = try await interceptor.process(response: response, for: prepared)
        }

        guard (200 ..< 300).contains(response.statusCode) else {
            throw HTTPErrorMapper.map(statusCode: response.statusCode, body: response.data)
        }
        return response
    }

    private func makeURLRequest(from request: HTTPRequest) throws -> URLRequest {
        guard let url = URL(string: request.path, relativeTo: configuration.baseURL)?.absoluteURL else {
            throw AppError.unknown(message: "Invalid path: \(request.path)")
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        if urlRequest.value(forHTTPHeaderField: "Accept") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        if request.body != nil, urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }

    private func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt + 1 < retryPolicy.maxAttempts else { return false }
        if error is CancellationError { return false }
        let mapped = HTTPErrorMapper.map(error)
        switch mapped {
        case .networkUnavailable:
            return true
        case let .server(statusCode, _) where statusCode >= 500:
            return true
        default:
            return false
        }
    }
}
