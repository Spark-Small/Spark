// Module: SparkAppShellTests

import SparkAppShell
import Testing

struct CommunityPushPayloadTests {
    @Test
    func parse_replyNotification_returnsPostID() {
        let payload = CommunityPushPayload.parse(userInfo: [
            "type": "community.reply",
            "post_id": "cp_001"
        ])
        #expect(payload == CommunityPushPayload(postID: "cp_001"))
    }

    @Test
    func parse_missingPostID_returnsNil() {
        #expect(CommunityPushPayload.parse(userInfo: ["type": "community.reply"]) == nil)
    }

    @Test
    func parse_nonCommunityType_returnsNil() {
        #expect(CommunityPushPayload.parse(userInfo: ["type": "messages.new", "post_id": "cp_001"]) == nil)
    }
}
