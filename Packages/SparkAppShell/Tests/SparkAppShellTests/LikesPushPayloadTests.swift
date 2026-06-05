// Module: SparkAppShellTests

import Foundation
import SparkAppShell
import Testing

struct LikesPushPayloadTests {
    @Test func parseInboundPush() {
        let payload = LikesPushPayload.parse(userInfo: ["type": "likes.inbound"])
        #expect(payload == LikesPushPayload(kind: .inbound))
    }

    @Test func parseMatchPushWithThread() {
        let payload = LikesPushPayload.parse(userInfo: [
            "type": "likes.match",
            "thread_id": "th_dm_u_like_2"
        ])
        #expect(payload == LikesPushPayload(kind: .match(threadID: "th_dm_u_like_2")))
    }

    @Test func ignoresUnknownType() {
        #expect(LikesPushPayload.parse(userInfo: ["type": "messages.new"]) == nil)
    }
}
