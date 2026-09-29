import Foundation
import XCTest
import CoordinateNetworking

final class APIEnvelopeTests: XCTestCase {
    struct Ping: Decodable, Equatable {
        let ok: Bool
    }

    func testDecodeEnvelopeSuccess() throws {
        let json = Data(#"{"code":0,"message":"ok","data":{"ok":true},"request_id":"r1"}"#.utf8)
        let envelope = try APIJSONCoding.makeDecoder().decode(APIEnvelope<Ping>.self, from: json)
        XCTAssertEqual(envelope.code, 0)
        XCTAssertEqual(envelope.data, Ping(ok: true))
        XCTAssertEqual(envelope.requestId, "r1")
    }

    func testDecodeISO8601Date() throws {
        struct Row: Decodable {
            let at: Date
        }
        let json = Data(#"{"at":"2026-09-04T09:30:00.123Z"}"#.utf8)
        let row = try APIJSONCoding.makeDecoder().decode(Row.self, from: json)
        XCTAssertEqual(Calendar.current.component(.year, from: row.at), 2026)
    }
}
