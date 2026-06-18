// Module: SparkNetworkingTests

import Foundation
import SparkCore
import SparkNetworking
import Testing

@Suite(.serialized)
struct HTTPClientTests {
    @Test func getDecodesSuccessResponse() async throws {
        StubURLProtocol.requestHandler = { request in
            let url = try #require(request.url)
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, Data("{\"count\":7}".utf8))
        }

        let config = APIConfiguration(baseURL: URL(string: "https://api.test")!)
        let client = HTTPClient(
            configuration: config,
            session: StubURLProtocolRegistration.makeSession()
        )
        let api = APIClient(http: client)
        struct CountDTO: Decodable, Sendable { let count: Int }
        let dto: CountDTO = try await api.get("/v1/messages/unread-count")
        #expect(dto.count == 7)
    }

    @Test func unauthorizedMapsToAppError() async throws {
        StubURLProtocol.requestHandler = { request in
            let url = try #require(request.url)
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)
            )
            return (response, Data())
        }
        let config = APIConfiguration(baseURL: URL(string: "https://api.test")!)
        let client = HTTPClient(configuration: config, session: StubURLProtocolRegistration.makeSession())
        do {
            _ = try await client.execute(HTTPRequest(path: "/secure"))
            Issue.record("Expected unauthorized error")
        } catch let error as AppError {
            #expect(error == .unauthorized)
        }
    }

    @Test func authenticated401TriggersSessionInvalidation() async throws {
        let spy = UnauthorizedInterceptorSpy()
        StubURLProtocol.requestHandler = { request in
            let url = try #require(request.url)
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)
            )
            return (response, Data())
        }

        let config = APIConfiguration(baseURL: URL(string: "https://api.test")!)
        let client = HTTPClient(
            configuration: config,
            session: StubURLProtocolRegistration.makeSession(),
            interceptors: [
                AuthorizationInterceptor(tokenProvider: FixedTokenProvider(token: "test-token")),
                UnauthorizedSessionInterceptor(invalidator: spy),
            ]
        )

        do {
            _ = try await client.execute(HTTPRequest(path: "/v1/messages/inbox", method: .get))
            Issue.record("Expected unauthorized error")
        } catch let error as AppError {
            #expect(error == .unauthorized)
        }

        #expect(await spy.count() == 1)
    }

    @Test func login401WithoutBearerSkipsSessionInvalidation() async throws {
        let spy = UnauthorizedInterceptorSpy()
        StubURLProtocol.requestHandler = { request in
            let url = try #require(request.url)
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)
            )
            return (response, Data())
        }

        let config = APIConfiguration(baseURL: URL(string: "https://api.test")!)
        let client = HTTPClient(
            configuration: config,
            session: StubURLProtocolRegistration.makeSession(),
            interceptors: [UnauthorizedSessionInterceptor(invalidator: spy)]
        )

        do {
            _ = try await client.execute(
                HTTPRequest(path: "/v1/auth/phone", method: .post, body: Data("{}".utf8))
            )
            Issue.record("Expected unauthorized error")
        } catch let error as AppError {
            #expect(error == .unauthorized)
        }

        #expect(await spy.count() == 0)
    }
}

private actor UnauthorizedInterceptorSpy: AuthSessionInvalidating {
    private var invalidationCount = 0

    func sessionDidBecomeUnauthorized() async {
        invalidationCount += 1
    }

    func count() async -> Int {
        invalidationCount
    }
}

private struct FixedTokenProvider: AccessTokenProviding {
    let token: String

    func accessToken() async -> String? { token }
}
