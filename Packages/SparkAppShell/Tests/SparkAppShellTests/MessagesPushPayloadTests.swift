// Module: SparkAppShellTests

import Foundation
import SparkAppShell
import Testing

struct MessagesPushPayloadTests {
    @Test func parseNewMessagePush() {
        let payload = MessagesPushPayload.parse(userInfo: [
            "type": "messages.new",
            "thread_id": "th_dm_u_like_2"
        ])
        #expect(payload == MessagesPushPayload(threadID: "th_dm_u_like_2"))
    }

    @Test func ignoresMissingThread() {
        #expect(MessagesPushPayload.parse(userInfo: ["type": "messages.new"]) == nil)
    }
}
