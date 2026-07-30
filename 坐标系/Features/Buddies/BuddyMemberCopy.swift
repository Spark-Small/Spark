//
//  BuddyMemberCopy.swift
//  坐标系
//
//  组织 / 工会成员轻量卡、成员列表、语音厅麦位文案。
//

import Foundation

nonisolated enum BuddyMemberCopy {
    static let profileTitle = "成员资料"
    static let listTitle = "全部成员"
    static let done = "完成"
    static let message = "发消息"
    static let openFullProfile = "查看完整资料"
    static let book = BuddyDetailCopy.book
    static let bookUnavailable = BuddyDetailCopy.bookUnavailable
    static let greet = BuddyDetailCopy.greet

    static let roleAdmin = "管理员"
    static let roleMember = "成员"
    static let roleAvailable = "可约"
    static let roleBusy = "档期已满"
    static let roleHost = "厅主"
    static let roleOnMic = "麦上"
    static let roleSelf = "我"

    static let viewAllMembers = "查看全部成员"
    static let collapseMembers = "收起成员"
    static let moreMembers = "更多成员"
    static let emptyMembersTitle = "暂无成员资料"
    static let emptyMembersDescription = "加入后可邀请同好，或去舞台发现更多人。"

    static let sourceSectionTitle = "来源"
    static let takeMic = "上麦"
    static let emptySeat = "空麦位"
    static let emptySeatHint = "点按申请上麦（演示）"
    static let leaveMic = "下麦"
    static let onMicDemo = "已上麦（演示）"
    static let offMicDemo = "已下麦"

    static func roleBadge(_ role: String) -> String { role }

    static func memberCount(_ count: Int) -> String { "共 \(count) 人" }

    static func circleSource(name: String) -> String { "同在组织「\(name)」" }

    static func guildSource(name: String) -> String { "来自工会「\(name)」" }

    static func voiceSource(title: String, isHost: Bool) -> String {
        isHost ? "「\(title)」厅主" : "正在「\(title)」麦上"
    }

    static func listAccessibility(nickname: String, role: String) -> String {
        "\(nickname)，\(role)"
    }

    static func seatAccessibility(nickname: String, isHost: Bool) -> String {
        "\(nickname)，\(isHost ? roleHost : roleOnMic)"
    }
}

/// 打开搭子资料时的入口上下文（轻量卡与完整详情共用）
enum BuddyProfileSource: Hashable {
    case discover
    case circle(name: String, topic: String)
    case guild(name: String, specialty: String)
    case voiceHall(title: String, isHost: Bool)

    var contextLine: String? {
        switch self {
        case .discover:
            nil
        case .circle(let name, _):
            BuddyMemberCopy.circleSource(name: name)
        case .guild(let name, _):
            BuddyMemberCopy.guildSource(name: name)
        case .voiceHall(let title, let isHost):
            BuddyMemberCopy.voiceSource(title: title, isHost: isHost)
        }
    }

    var emphasizesBooking: Bool {
        switch self {
        case .guild, .voiceHall: true
        case .discover, .circle: false
        }
    }
}

/// Sheet / 列表选中的成员
struct BuddyMemberProfileTarget: Identifiable, Hashable {
    let item: DiscoverBuddyItem
    var source: BuddyProfileSource
    var role: String

    var id: UUID { item.id }
}
