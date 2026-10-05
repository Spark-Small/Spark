//
//  ParticipantIdentity.swift
//  坐标系
//
//  参与身份单一读口：稳定 userID 优先，昵称仅回退。远程履约贯通仍待后端。
//

import CoordinateDomain
import Foundation

/// 报名 / 预约 / 邀约等业务识别「当前用户」与「是否同一人」。
enum ParticipantIdentity {
    /// 本机稳定 UUID（远程登录可 `LocalUserIdentity.adopt`）。
    static var currentUserID: UUID { LocalUserIdentity.current }

    /// 两边都有 userID 时只比 ID；否则昵称大小写不敏感。
    static func matches(
        nickname: String,
        userID: UUID?,
        otherNickname: String,
        otherUserID: UUID?
    ) -> Bool {
        BuddyIdentityMatching.matches(
            nickname: nickname,
            userID: userID,
            otherNickname: otherNickname,
            otherUserID: otherUserID
        )
    }

    /// 演示种子：由昵称派生可复现 UUID（非加密）。
    static func stableUserID(forNickname nickname: String) -> UUID {
        BuddyIdentityMatching.stableUserID(forNickname: nickname)
    }
}
