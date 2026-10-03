//
//  MessagesModel+Search.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

extension MessagesModel {
    func searchHistory(query: String) -> [ChatHistoryHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var hits: [ChatHistoryHit] = []
        for conversation in conversations where !conversation.isMessageRequest {
            hits.append(contentsOf: searchHistory(in: conversation.id, query: trimmed, title: conversation.title))
        }
        return hits.sorted { $0.sentAt > $1.sentAt }
    }

    /// 单会话聊天记录检索（群详情快捷入口）。
    func searchHistory(
        in conversationID: ChatConversation.ID,
        query: String
    ) -> [ChatHistoryHit] {
        let title = conversations.first(where: { $0.id == conversationID })?.title ?? ""
        return searchHistory(in: conversationID, query: query, title: title)
            .sorted { $0.sentAt > $1.sentAt }
    }

    private func searchHistory(
        in conversationID: ChatConversation.ID,
        query: String,
        title: String
    ) -> [ChatHistoryHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var hits: [ChatHistoryHit] = []
        for message in threads[conversationID] ?? [] where !message.isSystem {
            let hay = [
                message.text,
                message.linkTitle,
                message.linkSubtitle,
                message.locationName,
                message.previewText
            ].compactMap { $0 }.joined(separator: " ")
            if hay.localizedCaseInsensitiveContains(trimmed) {
                hits.append(
                    ChatHistoryHit(
                        id: UUID(),
                        conversationID: conversationID,
                        conversationTitle: title,
                        messageID: message.id,
                        snippet: message.previewText,
                        sentAt: message.sentAt
                    )
                )
            }
        }
        return hits
    }
}
