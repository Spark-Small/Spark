// Module: SparkNotificationsTests — Push payload parsing.

import Foundation
import SparkNotifications
import Testing

struct MessagesPushPayloadTests {
    @Test func parse_newMessage_returnsThreadID() {
        let payload = MessagesPushPayload.parse(userInfo: [
            "type": "messages.new",
            "thread_id": "th_dm_u_like_2"
        ])
        #expect(payload == MessagesPushPayload(threadID: "th_dm_u_like_2"))
    }

    @Test func parse_missingThreadID_returnsNil() {
        #expect(MessagesPushPayload.parse(userInfo: ["type": "messages.new"]) == nil)
    }
}

struct CommunityPushPayloadTests {
    @Test func parse_replyNotification_returnsPostID() {
        let payload = CommunityPushPayload.parse(userInfo: [
            "type": "community.reply",
            "post_id": "cp_001"
        ])
        #expect(payload == CommunityPushPayload(postID: "cp_001"))
    }

    @Test func parse_missingPostID_returnsNil() {
        #expect(CommunityPushPayload.parse(userInfo: ["type": "community.reply"]) == nil)
    }

    @Test func parse_unrelatedType_returnsNil() {
        #expect(CommunityPushPayload.parse(userInfo: ["type": "messages.new", "post_id": "cp_001"]) == nil)
    }
}

struct ActivityPushPayloadTests {
    @Test func parse_activityID_returnsPayload() {
        let payload = ActivityPushPayload.parse(userInfo: ["activity_id": "act_1"])
        #expect(payload == ActivityPushPayload(activityID: "act_1"))
    }

    @Test func parse_typedActivity_returnsPayload() {
        let payload = ActivityPushPayload.parse(userInfo: [
            "type": "activity.reminder",
            "activity_id": "act_2"
        ])
        #expect(payload == ActivityPushPayload(activityID: "act_2"))
    }
}

struct NoOpDeviceTokenUploaderTests {
    @Test func uploadCompletesWithoutError() async {
        await NoOpDeviceTokenUploader().upload(apnsToken: Data([0x01, 0x02]))
    }
}
