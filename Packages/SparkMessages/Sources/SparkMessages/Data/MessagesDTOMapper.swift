// Module: SparkMessages — Maps API DTOs to domain models.

import Foundation

enum MessagesDTOMapper {
    static func thread(from dto: MessageThreadDTO) throws -> MessageThread {
        guard let date = parseISO8601(dto.lastActivityAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        return MessageThread(
            threadID: MessageThreadID(dto.id),
            peerDisplayName: dto.peerDisplayName,
            lastMessagePreview: dto.lastMessagePreview,
            lastActivityAt: date,
            unreadCount: dto.unreadCount
        )
    }

    static func message(from dto: ChatMessageDTO) throws -> ChatMessage {
        guard let date = parseISO8601(dto.sentAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        return ChatMessage(
            id: dto.id,
            threadID: MessageThreadID(dto.threadId),
            body: dto.body,
            sentAt: date,
            isFromCurrentUser: dto.isFromCurrentUser
        )
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
