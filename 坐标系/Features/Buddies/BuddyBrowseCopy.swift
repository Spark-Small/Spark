//
//  BuddyBrowseCopy.swift
//  坐标系
//
//  搭子发现 / 货架 / 语音厅 / 顶栏文案。
//

import Foundation

nonisolated enum BuddyBrowseCopy {
    static let rootTitle = "搭子"

    enum Shelf {
        static let nearbyTitle = "附近的人"
        static let affinityTitle = "同频的人"
        static let followingTitle = "接着逛"
        static let tonightTitle = "今晚有空"
        static let leaderboardTitle = "推荐陪玩"
        static let listTitle = "推荐"
        static let activeWallTitle = "刚活跃"
        static let paidWallTitle = "更多陪玩"
    }

    static let circlesTitle = "同城俱乐部"
    static let availableOnlyChip = "仅可约"
    static let leaderboardRankTitle = "榜期"
    /// 发现 / 详情 / Context 陪玩主动词（短口语，对齐 Calendar「预约」）
    static let bookAction = BuddyDetailCopy.quickBook
    static let bookUnavailable = BuddyDetailCopy.bookUnavailable
    /// 同好卡默认联系动作（正式路径由 `peerContactActionTitle` 覆盖）
    static let chatAction = "聊天"
    static let intentMatchBadge = "契合"

    enum ContextMenu {
        static let share = "分享"
    }

    enum MyBookings {
        static func statusFooter(count: Int, needsAttention: Int) -> String {
            if needsAttention > 0 {
                return "\(needsAttention) 笔待确认或待支付 · 共 \(count) 笔进行中"
            }
            return "\(count) 笔进行中"
        }
    }

    enum Toolbar {
        static let filter = "筛选"
        static let filterActive = "筛选（已启用）"
    }

    enum Empty {
        static let noMatchTitle = "没有找到可约的人"
        static let noMatchBody = "放宽性别、距离或兴趣后再试"
        static let locatingTitle = "正在获取位置…"
        static let locatingBody = "定位后会按同城推荐可约的人；也可在筛选里指定城市"
        static let nearbyEmptyTitle = "附近暂时没有可约的人"
        static let nearbyEmptyBody = "扩大距离，或换个城市再找搭子 / 陪玩"
        static let noPaidNearby = "附近暂无可约的陪玩"
        static let noFreeFiltered = "没有符合条件的同好"
        static let noPaidFiltered = "没有符合条件的陪玩"
        static let clearFilters = "清除筛选，重新找人"
        static let adjustFilters = "调整找人条件"
        static let pickCity = "指定城市找人"
        static let relaxFilters = "放宽条件继续找"
        static let clubsEmptyTitle = "暂时没有可加入的俱乐部"
        static let clubsEmptyBody = "附近暂时没有新俱乐部；可在「我的」创建，或稍后再来"
        static let clubsEmptyAction = "去我的创建"
        static let clubsFilteredEmpty = "没有符合条件的俱乐部"
    }

    enum Guilds {
        static let listTitle = "我的工会"
        static let emptyTitle = "还没有关注工会"
        static let emptyBody = "在搭子 · 陪玩页关注工会后，会出现在这里。"
        static let browseCTA = "去搭子看看"
    }

    enum ShelfA11y {
        static let enterVoiceHall = "进厅"
        static let enterVoiceHallHint = "进入语音厅"
        static let openCircleHint = "打开俱乐部资料"
        static let coverSwipeHint = "左右滑动切换照片或视频，轻点打开资料"
        static func coverMediaCount(_ count: Int) -> String {
            "含 \(count) 张照片"
        }
        static func ordersCount(_ n: Int) -> String { "\(n) 单" }
        static func topRankLabel(rank: Int, nickname: String, price: String) -> String {
            "第\(rank)名，\(nickname)，\(price)"
        }
        static func openEntryHint(_ title: String) -> String { "打开\(title)" }
    }

    enum VoiceHall {
        static let sectionTitle = "语音厅"
        static let sectionSubtitle = "实时语音闲聊，与预约陪玩分开"
        static let roomTitle = "语音厅"
        static let infoSection = "厅信息"
        static let topic = "主题"
        static let city = "城市"
        static let host = "厅主"
        static let live = "直播中"
        static let idle = "休息中"
        static let roomFooter = "点麦位查看资料；空麦位可申请上麦。"
        static let leave = "离开"
    }

    enum ModeSwitch {
        static let picker = "浏览模式"
    }

    static let recentsTitle = "最近浏览"
    static let recentsEmptyTitle = "还没有浏览记录"
    static let recentsEmptyDescription = "查看搭子、陪玩或俱乐部详情后会出现在这里"
    static let recentsClear = "清空"
    static let recentsSectionPeople = "看过的人"
    static let recentsSectionClubs = "看过的俱乐部"

    enum ScrollAnchor {
        static let discoverBrowse = "buddies-discover-browse"
    }

    enum PaidShelf {
        static var leaderboardTitle: String { Shelf.leaderboardTitle }
        static let leaderboardSubtitle = "按成单与评价排序"
        /// 详情服务档行内 CTA（与发现主动词同为「预约」）
        static let bookCTA = BuddyDetailCopy.quickBook
        static let negotiateCTA = "约聊议价"
        static let tabProfile = "资料"
        static let tabService = "服务"
        static let tabReviews = "评价"
        static let detailTabPicker = "详情分区"
        static func tabReviewsCount(_ n: Int) -> String { "评价 \(n)" }
    }

    enum ModelCopy {
        static let bookingThreadTitlePrefix = "陪玩"
        static let locating = "正在定位"
        static func locatedAt(_ place: String) -> String { "当前定位 \(place)" }
        static let clubNameTooShort = "名称至少 2 个字"
        static let clubNameTooLong = "名称不超过 20 个字"
        static let clubNameTaken = "已有同名俱乐部，请换一个名称"
        static let memberFallback = "成员"
        static let seedLastActive = "今天活跃"
        static let seedLookingFor = "同城约局"
    }

    enum OrgPoster {
        static let guildInfo = "工会信息"
        static let guildName = "工会名称"
        static let specialty = "擅长"
        static let priceFrom = "起步"
        static let weeklyOrders = "本周单量"
        static let followGuild = "关注工会"
        static let unfollowGuild = "取消关注"
        static let pinGuild = "置顶该工会"
        static let guildNickname = "我在本工会的昵称"
        static func memberCount(_ n: Int) -> String { "\(n) 人" }
        static func membersA11y(_ n: Int) -> String { "\(n) 成员" }
    }
}