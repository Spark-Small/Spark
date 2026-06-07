// Module: SparkMessagesTests — DTO mapper coverage.

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
              "title": "Weekend hike",
              "starts_at": "2026-06-07T09:00:00Z",
              "attendee_count": 5
            }
          }],
          "unmessaged_matches": [],
          "dm_conversations": [{
            "id": "th_dm_u_1",
            "kind": "dm",
            "display_name": "Alex",
            "last_message_preview": "Hi",
            "last_message_at": "2026-06-04T10:00:00Z",
            "unread_count": 1
          }],
          "group_conversations": [{
            "id": "th_activity_act_1",
            "kind": "group_chat",
            "display_name": "Hike group",
            "last_message_preview": "See you",
            "last_message_at": "2026-06-04T11:00:00Z",
            "unread_count": 2,
            "member_count": 4,
            "is_archived": false
          }]
        }
        """
        let dto = try JSONDecoder().decode(MessagesInboxResponseDTO.self, from: Data(json.utf8))
        let inbox = try MessagesDTOMapper.inbox(from: dto)
        #expect(inbox.actionItems.count == 1)
        #expect(inbox.dmConversations.count == 1)
        #expect(inbox.activeGroupChats.count == 1)
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
              "title": "Weekend hike",
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

    @Test func messageAndThreadMapping() throws {
        let threadJSON = """
        {
          "id": "th_dm_u_1",
          "peer_display_name": "Alex",
          "last_message_preview": "Hi",
          "last_activity_at": "2026-06-04T10:00:00Z",
          "unread_count": 1
        }
        """
        let threadDTO = try JSONDecoder().decode(MessageThreadDTO.self, from: Data(threadJSON.utf8))
        let thread = try MessagesDTOMapper.thread(from: threadDTO)
        #expect(thread.threadID.rawValue == "th_dm_u_1")

        let messageJSON = """
        {
          "id": "msg_1",
          "thread_id": "th_dm_u_1",
          "body": "Hello",
          "sent_at": "2026-06-04T10:01:00Z",
          "is_from_current_user": true,
          "kind": "text"
        }
        """
        let messageDTO = try JSONDecoder().decode(ChatMessageDTO.self, from: Data(messageJSON.utf8))
        let message = try MessagesDTOMapper.message(from: messageDTO)
        #expect(message.body == "Hello")
    }

    @Test func conversationContextMapsSharedActivities() throws {
        let json = """
        {
          "shared_activities": [{
            "id": "act_1",
            "title": "Coffee",
            "starts_at": "2026-06-07T18:00:00Z",
            "attendee_count": 2
          }],
          "relationship_status": "matched"
        }
        """
        let dto = try JSONDecoder().decode(ConversationContextResponseDTO.self, from: Data(json.utf8))
        let context = try MessagesDTOMapper.conversationContext(from: dto)
        #expect(context.sharedActivities.count == 1)
        #expect(context.relationshipStatus == "matched")
    }

    @Test func inboxMapsActivityInviteAndChangeActionItems() throws {
        let json = """
        {
          "action_items": [
            {
              "id": "action_invite",
              "type": "activity_invite",
              "priority": 1,
              "created_at": "2026-06-04T08:00:00Z",
              "invite": {
                "id": "inv_1",
                "activity": {
                  "id": "act_2",
                  "title": "Board games",
                  "starts_at": "2026-06-08T19:00:00Z",
                  "attendee_count": 3
                },
                "inviter": {
                  "id": "u_host",
                  "display_name": "Host"
                }
              }
            },
            {
              "id": "action_change",
              "type": "activity_changed",
              "priority": 2,
              "created_at": "2026-06-04T09:00:00Z",
              "change": {
                "id": "chg_1",
                "kind": "rescheduled",
                "activity": {
                  "id": "act_2",
                  "title": "Board games",
                  "starts_at": "2026-06-09T19:00:00Z",
                  "attendee_count": 3
                },
                "host_name": "Host",
                "previous_schedule_line": "Fri 7pm"
              }
            }
          ],
          "unmessaged_matches": [{
            "id": "match_1",
            "matched_at": "2026-06-04T07:00:00Z",
            "thread_id": "th_dm_u_2",
            "user": {
              "id": "u_match",
              "display_name": "Match"
            }
          }],
          "dm_conversations": [],
          "group_conversations": []
        }
        """
        let dto = try JSONDecoder().decode(MessagesInboxResponseDTO.self, from: Data(json.utf8))
        let inbox = try MessagesDTOMapper.inbox(from: dto)
        #expect(inbox.actionItems.count == 2)
        #expect(inbox.unmessagedMatches.count == 1)
    }
}
