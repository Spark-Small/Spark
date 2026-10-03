//
//  ConversationPeerProfileRoute.swift
//  坐标系
//
//  会话内点顶栏 / 头像进资料：好友 → Contacts 式资料卡；非好友 → 发现详情。
//

import Foundation
import CoordinateModels

enum ConversationPeerProfileRoute: Identifiable, Hashable {
    /// 通讯录好友资料（发消息 / 通话；无「加好友」）
    case friend(nickname: String)
    /// 发现向资料（未加好友时的搭子卡）
    case discover(DiscoverBuddyItem)

    var id: String {
        switch self {
        case .friend(let nickname):
            "friend:\(nickname.lowercased())"
        case .discover(let item):
            "discover:\(item.id.uuidString)"
        }
    }
}
