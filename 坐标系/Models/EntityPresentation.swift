//
//  EntityPresentation.swift
//  坐标系
//
//  依赖 App 服务的实体展示扩展（封面、距离阈值、演示参与者等）。
//

import Foundation
import SwiftUI
import CoordinateModels

extension Activity {
    var isNearby: Bool { distanceKM <= RecommendationConfig.nearbyKM }

    var coverPhoto: CommunityPhotoRef? {
        if let name = localCoverName,
           let url = CommunityPhotoStore.fileURL(named: name) {
            return .file(url)
        }
        if let asset = ActivityBundledCovers.assetName(for: id) {
            return .asset(asset)
        }
        return .seeded(seed: coverSeed, symbol: coverSymbol)
    }

    /// 展示用参与者：优先真实名单，种子数据兜底
    var displayParticipants: [String] {
        if !participantNames.isEmpty {
            return participantNames
        }
        let pool = ["阿凯", "Mia", "小周", "阿禾", "Leo", "林夏", "坐标系小队"]
        var names = [hostName]
        let extras = pool.filter { $0 != hostName }
        let need = max(joined - 1, 0)
        names.append(contentsOf: extras.prefix(need))
        return Array(names.prefix(max(joined, 1)))
    }
}

extension ChatConversation {
    /// 标题旁展示，样式与未读 `[3条]` 一致
    var eventTimeText: String? {
        guard kind == .activity, let eventAt else { return nil }
        return "[\(Formatters.activityEventTime(from: eventAt))]"
    }
}

extension AppUser {
    /// 创建当前用户资料，默认绑定本机稳定 UUID。
    static func localDefault(
        name: String,
        handle: String,
        city: String,
        bio: String,
        joinedCount: Int,
        hostedCount: Int,
        buddyCount: Int,
        interests: [String] = [],
        lookingFor: String = "",
        avatarLocalName: String? = nil,
        voiceIntroDuration: Double? = nil,
        voiceIntroCaption: String? = nil
    ) -> AppUser {
        AppUser(
            id: LocalUserIdentity.current,
            name: name,
            handle: handle,
            city: city,
            bio: bio,
            joinedCount: joinedCount,
            hostedCount: hostedCount,
            buddyCount: buddyCount,
            interests: interests,
            lookingFor: lookingFor,
            avatarLocalName: avatarLocalName,
            voiceIntroDuration: voiceIntroDuration,
            voiceIntroCaption: voiceIntroCaption
        )
    }
}
