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

    enum Toolbar {
        static let filter = "筛选"
        static let filterActive = "筛选（已启用）"
    }

    enum Empty {
        static let noMatchTitleFree = "没有找到合适的同好"
        static let noMatchTitlePaid = "没有找到可约的陪玩"
        static let noMatchBody = "放宽性别、距离或兴趣后再试"
        static let locatingTitle = "正在获取位置…"
        /// 与 `matchesBrowseLocation` 软启动行为对齐：GPS 不硬筛样例/远程目录。
        static let locatingBody = "定位用于天气与当前位置展示；发现列表暂不按 GPS 硬筛，也可在筛选里指定城市"
        static let nearbyEmptyTitle = "暂时没有合适的人"
        static let nearbyEmptyTitleFree = "暂时没有合适的同好"
        static let nearbyEmptyTitlePaid = "暂时没有可约的陪玩"
        static let nearbyEmptyBody = "可放宽距离、性别或兴趣；在筛选里指定城市后才会按城过滤"
        static let noPaidNearby = "暂无可约的陪玩"
        static let noFreeFiltered = "没有符合条件的同好"
        static let noPaidFiltered = "没有符合条件的陪玩"
        static let clearFilters = "清除筛选，重新找人"
        static let adjustFilters = "调整找人条件"
        static let pickCity = "指定城市找人"
        static let relaxFilters = "放宽条件继续找"
        static let recentsBackToBrowse = "回找搭子继续看"
        static let clubsEmptyTitle = "暂时没有可加入的俱乐部"
        static let clubsEmptyBody = "软启动暂不按定位硬筛；可在筛选指定城市，或在「我的 · 我的俱乐部」创建"
        static let clubsEmptyAction = "去我的俱乐部"
        static let clubsFilteredEmpty = "没有符合条件的俱乐部"
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
        static let menuHint = "切换找搭子、约陪玩、俱乐部或最近浏览"
    }

    static let recentsTitle = "最近浏览"
    static let recentsEmptyTitle = "还没有浏览记录"
    static let recentsEmptyDescription = "查看搭子、陪玩或俱乐部详情后会出现在这里"
    static let recentsClear = "清空"
    static let recentsBack = "返回"
    static func recentsBackHint(_ previousTitle: String) -> String {
        "回到\(previousTitle)"
    }
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
        static let tabPosts = "动态"
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