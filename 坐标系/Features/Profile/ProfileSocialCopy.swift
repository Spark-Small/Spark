//
//  ProfileSocialCopy.swift
//  坐标系
//
//  「我的」社交四列：获赞说明 / 互关·关注·粉丝列表文案。
//

import Foundation

enum ProfileSocialGraphKind: String, Hashable, CaseIterable, Identifiable {
    case mutual
    case following
    case fans

    var id: String { rawValue }

    var navigationTitle: String {
        switch self {
        case .mutual: ProfileSocialCopy.mutualTitle
        case .following: ProfileSocialCopy.followingTitle
        case .fans: ProfileSocialCopy.fansTitle
        }
    }
}

enum ProfileSocialCopy {
    static let likesLabel = "获赞数"
    static let mutualLabel = "互关"
    static let followingLabel = "关注"
    static let fansLabel = "粉丝数"

    static let likesDismiss = "我知道了"
    static let likesAccessibilityHint = "查看获赞说明"

    static let mutualTitle = "互关"
    static let followingTitle = "关注"
    static let fansTitle = "粉丝"

    static let searchPrompt = "搜索"
    static let unfollow = "取消关注"
    static let openProfileHint = "查看资料"

    static let mutualEmptyTitle = "还没有互关"
    static let mutualEmptyDescription = "关注的好友会出现在这里。"
    static let followingEmptyTitle = "还没有关注"
    static let followingEmptyDescription = "在广场发现作者并关注后，会出现在这里。"
    static let fansEmptyTitle = "还没有粉丝"
    static let fansEmptyDescription = "粉丝列表需要服务端关系图；当前本机不展示估算人数。"

    static let mutualFooter = "互关 = 已关注且已是好友。"
    static let followingFooter = "仅本机已关注的作者；取消关注后列表会更新。"
    static let fansFooter = "反向粉丝图尚未接入；不展示示例人数。"

    static func likesTitle(name: String, count: Int) -> String {
        "「\(name)」共获得 \(count) 个赞"
    }

    /// 诚实口径：仅统计本机可知的原创帖获赞，不冒充全平台作品类型。
    static let likesDescription = "获赞数包含你发布的帖子所获点赞。"

    static func emptyTitle(for kind: ProfileSocialGraphKind) -> String {
        switch kind {
        case .mutual: mutualEmptyTitle
        case .following: followingEmptyTitle
        case .fans: fansEmptyTitle
        }
    }

    static func emptyDescription(for kind: ProfileSocialGraphKind) -> String {
        switch kind {
        case .mutual: mutualEmptyDescription
        case .following: followingEmptyDescription
        case .fans: fansEmptyDescription
        }
    }

    static func footer(for kind: ProfileSocialGraphKind) -> String {
        switch kind {
        case .mutual: mutualFooter
        case .following: followingFooter
        case .fans: fansFooter
        }
    }
}
