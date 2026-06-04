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
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
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
            let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!
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
}
