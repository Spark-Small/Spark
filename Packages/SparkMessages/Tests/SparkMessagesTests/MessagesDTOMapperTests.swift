// Module: SparkMessagesTests

@testable import SparkMessages
import Foundation
import Testing

struct MessagesDTOMapperTests {
    @Test func inboxMapsActionItemsAndConversations() throws {
        let json = """
        {
          "action_items": [{
            "id": "action_1",
            "type": "waitlist_promoted",
            "priority": 0,
            "created_at": "2026-06-04T08:00:00Z",
            "activity": {
              "id": "act_1",
              "title": "周末徒步",
              "starts_at": "2026-06-07T09:00:00Z",
              "attendee_count": 5
            }
          }],
          "unmessaged_matches": [],
          "dm_conversations": [{
            "id": "th_dm_u_1",
            "kind": "dm",
            "display_name": "阿乐",
            "last_message_preview": "你好",
            "last_message_at": "2026-06-04T10:00:00Z",
            "unread_count": 1
          }],
          "group_conversations": []
        }
        """
        let dto = try JSONDecoder().decode(MessagesInboxResponseDTO.self, from: Data(json.utf8))
        let inbox = try MessagesDTOMapper.inbox(from: dto)
        #expect(inbox.actionItems.count == 1)
        #expect(inbox.dmConversations.count == 1)
        #expect(inbox.dmConversations.first?.threadID.isDirectMessage == true)
    }

    @Test func inboxRejectsInvalidCreatedAt() throws {
        let json = """
        {
          "action_items": [{
            "id": "action_1",
            "type": "waitlist_promoted",
            "priority": 0,
            "created_at": "not-a-date",
            "activity": {
              "id": "act_1",
              "title": "周末徒步",
              "starts_at": "2026-06-07T09:00:00Z",
              "attendee_count": 5
            }
          }],
          "unmessaged_matches": [],
          "dm_conversations": [],
          "group_conversations": []
        }
        """
        let dto = try JSONDecoder().decode(MessagesInboxResponseDTO.self, from: Data(json.utf8))
        #expect(throws: MessagesError.self) {
            try MessagesDTOMapper.inbox(from: dto)
        }
    }
}
