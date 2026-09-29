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
            for message in threads[conversation.id] ?? [] where !message.isSystem {
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
                            conversationID: conversation.id,
                            conversationTitle: conversation.title,
                            messageID: message.id,
                            snippet: message.previewText,
                            sentAt: message.sentAt
                        )
                    )
                }
            }
        }
        return hits.sorted { $0.sentAt > $1.sentAt }
    }
}
