//
//  Models.swift
//  坐标系
//
//  社区展示扩展与消息搜索命中。
//

import Foundation
import SwiftUI
import CoordinateModels

extension CommunityPost {
    var isRepost: Bool { repostedFromID != nil }

    var messageText: String {
        if let quote = quoteText?.trimmingCharacters(in: .whitespacesAndNewlines), !quote.isEmpty {
            return quote
        }
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var shareText: String {
        "【坐标系·社区】\(messageText)"
    }

    func isOwned(by currentUserName: String) -> Bool {
        author == currentUserName
    }

    var displayPhotos: [CommunityPhotoRef] {
        if !localPhotoNames.isEmpty {
            return localPhotoNames.compactMap { name in
                CommunityPhotoStore.fileURL(named: name).map(CommunityPhotoRef.file)
            }
        }
        let seeds = photoSeeds.isEmpty ? [abs(id.hashValue % 9000) + 200] : photoSeeds
        let symbol = tags.first.flatMap { BuddyHobbyOption(rawValue: $0)?.systemImage }
            ?? "sparkles"
        return seeds.map { .seeded(seed: $0, symbol: symbol) }
    }

    var coverPhoto: CommunityPhotoRef? { displayPhotos.first }
}

extension CommunityComment {
    var isReply: Bool { parentID != nil }

    func isOwned(by currentUserName: String) -> Bool {
        author == currentUserName
    }
}

enum CommunityPhotoRef: Hashable {
    case remote(URL)
    case file(URL)
    case asset(String)
    case seeded(seed: Int, symbol: String)

    var isVideo: Bool {
        switch self {
        case .file(let url):
            return CommunityPhotoStore.isVideo(url: url)
        default:
            return false
        }
    }

    var videoURL: URL? {
        guard isVideo, case .file(let url) = self else { return nil }
        return url
    }
}

struct ChatHistoryHit: Identifiable, Hashable {
    let id: UUID
    var conversationID: UUID
    var conversationTitle: String
    var messageID: UUID
    var snippet: String
    var sentAt: Date
}
