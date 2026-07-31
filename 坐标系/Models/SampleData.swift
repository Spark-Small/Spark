//
//  SampleData.swift
//  坐标系
//
//  扩充后的上海 + 成都本地种子数据；部分活动用内置封面图，其余走 SeededSceneFill。
//

import Foundation

enum SampleData {
    static let currentUserInterests = ["羽毛球", "骑行", "火锅局", "桌游", "探店"]

    static let currentUser = AppUser(
        name: "林屿",
        handle: "@linyu",
        city: "上海",
        bio: "爱打球、吃火锅、周末约局。有空就出来玩。",
        joinedCount: 18,
        hostedCount: 6,
        buddyCount: 42,
        interests: currentUserInterests
    )

    // MARK: - Helpers

    private static func day(_ offset: Int, hour: Int, minute: Int = 0) -> Date {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: offset, to: .now) ?? .now
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
    }

    private static func hours(_ h: Double) -> Date {
        .now.addingTimeInterval(3600 * h)
    }

    // Stable IDs so relatedActivity / catalog refresh stay consistent
    static func activityID(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "C0000000-0000-4000-8000-%012d", n))!
    }

    private static func uid(_ n: Int) -> UUID {
        activityID(n)
    }

    private static func chatID(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "A0000000-0000-4000-8000-%012d", n))!
    }

    private static func postID(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "B0000000-0000-4000-8000-%012d", n))!
    }

    // MARK: - Activities（种子 + 扩充目录，供长列表分区推荐）

    /// 基础 22 场 + 扩充目录；稳定 ID，目录升级时按 ID 合并；写入关联兴趣组织
    static let activities: [Activity] = (seedActivities + SampleActivityCatalog.extra).map(attachingRelatedCircle)

    /// 活动详情 / 推荐用：显式关联优先，否则按地区 + 主题推断
    static func relatedCircle(for activity: Activity) -> InterestCircle? {
        if let id = activity.relatedCircleID,
           let circle = interestCircles.first(where: { $0.id == id }) {
            return circle
        }
        return suggestedCircle(for: activity)
    }

    static func circle(id: UUID) -> InterestCircle? {
        interestCircles.first { $0.id == id }
    }

    private static func attachingRelatedCircle(_ activity: Activity) -> Activity {
        guard activity.relatedCircleID == nil,
              let circle = suggestedCircle(for: activity) else { return activity }
        var next = activity
        next.relatedCircleID = circle.id
        return next
    }

    private static func suggestedCircle(for activity: Activity) -> InterestCircle? {
        let district = districtToken(from: activity.location)
        let metro = metroToken(from: activity.location)
        let blob = ([activity.title, activity.summary, activity.category.title] + activity.tags)
            .joined(separator: " ")

        var best: (InterestCircle, Int)?
        for circle in interestCircles {
            let circleMetro = metroToken(from: circle.city)
            if let metro, let circleMetro, metro != circleMetro { continue }

            var score = 0
            let circleDistrict = districtToken(from: circle.city)
            if let district, let circleDistrict,
               district.contains(circleDistrict) || circleDistrict.contains(district) {
                score += 5
            }
            if blob.contains(circle.topic) { score += 3 }
            for tag in circle.tags where blob.contains(tag) {
                score += 2
            }
            for tag in activity.tags where circle.tags.contains(where: { $0.contains(tag) || tag.contains($0) }) {
                score += 2
            }
            if score > (best?.1 ?? 0) {
                best = (circle, score)
            }
        }
        guard let best, best.1 >= 4 else { return nil }
        return best.0
    }

    private static func districtToken(from location: String) -> String? {
        let parts = location
            .split(separator: "·", maxSplits: 1, omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let first = parts.first else { return nil }
        if first == "上海" || first == "成都" {
            guard parts.count > 1 else { return nil }
            return parts[1].split(whereSeparator: { $0 == " " || $0 == "/" }).first.map(String.init)
        }
        return first.split(whereSeparator: { $0 == " " || $0 == "/" }).first.map(String.init)
    }

    private static func metroToken(from location: String) -> String? {
        if location.contains("成都") { return "成都" }
        if location.contains("上海") { return "上海" }
        return nil
    }

    private static let seedActivities: [Activity] = [
        Activity(
            id: uid(1), title: "午间羽毛球快打", category: .outdoorSports,
            location: "静安 · 静安体育中心", date: day(0, hour: 12, minute: 15),
            capacity: 8, joined: 4, hostName: "阿禾",
            summary: "午休 50 分钟混打，水平 2.5–3.0，有拍可借。打完各自回公司。",
            fee: "AA 约 25／人", tags: ["羽毛球", "午休"], distanceKM: 0.8,
            participantNames: ["阿禾", "林夏", "小周", "Coco"],
            latitude: 31.2234, longitude: 121.4458
        ),
        Activity(
            id: uid(2), title: "外滩滨江夜骑", category: .outdoorSports,
            location: "黄浦 · 外滩观光隧道出口集合", date: hours(6),
            capacity: 12, joined: 9, hostName: "阿凯",
            summary: "沿江往返约 8 公里，入门配速。骑完便利店补给，不强制续摊。",
            fee: "免费（自备车）", tags: ["骑行", "夜骑", "入门友好"], distanceKM: 2.4,
            participantNames: ["阿凯", "林夏", "Leo", "阿禾", "小周", "Yuna", "Coco", "Noon", "林屿"],
            latitude: 31.2400, longitude: 121.4900
        ),
        Activity(
            id: uid(3), title: "下班奶茶续命局", category: .interestSocial,
            location: "黄浦 · 新天地地铁口集合", date: day(1, hour: 19),
            capacity: 8, joined: 5, hostName: "Mia",
            summary: "两家热门奶茶店打卡，边喝边聊最近忙啥，不整虚的。",
            fee: "人均约 30（自费）", tags: ["探店", "聊天局", "奶茶"], distanceKM: 1.6,
            participantNames: ["Mia", "林夏", "阿凯", "小周", "Noon"],
            latitude: 31.2110, longitude: 121.4660
        ),
        Activity(
            id: uid(4), title: "周末篮球 3V3", category: .outdoorSports,
            location: "徐汇 · 上海体育场外场", date: hours(52),
            capacity: 12, joined: 9, hostName: "阿梨",
            summary: "半场三对三，水平休闲局。自备球鞋，球可以共用。",
            fee: "免费", tags: ["篮球", "周末"], distanceKM: 3.2,
            participantNames: ["阿梨", "Coco", "林夏", "小周", "阿禾", "Noon", "Leo", "阿凯", "Yuna"],
            latitude: 31.1830, longitude: 121.4400
        ),
        Activity(
            id: uid(5), title: "烧烤撸串夜局", category: .food,
            location: "杨浦 · 国定路烧烤一条街", date: hours(30),
            capacity: 10, joined: 7, hostName: "串串阿木",
            summary: "已订大桌，肉串海鲜随便点，人均可控。能喝就喝，不劝酒。",
            fee: "人均 80–110", tags: ["烧烤", "晚饭", "夜宵"], distanceKM: 8.5,
            participantNames: ["串串阿木", "Mia", "Leo", "Yuna", "小周", "Noon", "Coco"],
            latitude: 31.3000, longitude: 121.5100
        ),
        Activity(
            id: uid(6), title: "火锅拼桌局", category: .food,
            location: "徐汇 · 天钥桥路火锅店（已订）", date: hours(28),
            capacity: 8, joined: 5, hostName: "小周",
            summary: "鸳鸯锅，忌口群里说。迟到超 15 分钟可能开吃。",
            fee: "人均 120–150", tags: ["火锅局", "晚饭"], distanceKM: 2.1,
            participantNames: ["小周", "Mia", "林夏", "Coco", "Noon"],
            latitude: 31.1980, longitude: 121.4400
        ),
        Activity(
            id: uid(7), title: "羽毛球混双打野", category: .outdoorSports,
            location: "浦东 · 源深体育中心 3 号馆", date: hours(28),
            capacity: 8, joined: 5, hostName: "阿凯",
            summary: "水平大约 3.0–3.5。场地已定 19:00–21:00，有球拍可借一把。",
            fee: "AA 约 35／人", tags: ["羽毛球", "运动搭子"], distanceKM: 5.8,
            participantNames: ["阿凯", "Yuna", "Leo", "Noon", "Coco"],
            latitude: 31.2338, longitude: 121.5326
        ),
        Activity(
            id: uid(8), title: "苏州河夜跑 5K", category: .outdoorSports,
            location: "普陀 · 梦清园西门", date: day(0, hour: 19, minute: 30),
            capacity: 16, joined: 11, hostName: "Noon",
            summary: "轻松配速，终点有 10 分钟拉伸。新手跟最后一组，不甩人。",
            fee: "免费", tags: ["跑步", "夜跑"], distanceKM: 4.5,
            participantNames: ["Noon", "Leo", "阿凯", "Coco", "林夏"],
            latitude: 31.2420, longitude: 121.4480
        ),
        Activity(
            id: uid(9), title: "热映电影拼场", category: .entertainment,
            location: "徐汇 · 衡山路影城", date: day(2, hour: 19, minute: 30),
            capacity: 8, joined: 5, hostName: "麦旋风",
            summary: "看当前热映，座位一起订。散场可续杯奶茶，不强制。",
            fee: "票价自理", tags: ["电影夜", "逛街"], distanceKM: 2.0,
            participantNames: ["麦旋风", "Mia", "林夏", "小周", "Coco"],
            latitude: 31.2105, longitude: 121.4440
        ),
        Activity(
            id: uid(10), title: "乒乓球娱乐局", category: .outdoorSports,
            location: "浦东 · 源深乒乓球馆", date: day(3, hour: 19),
            capacity: 8, joined: 4, hostName: "林夏",
            summary: "娱乐对拉，不打比赛。球拍馆里有租。",
            fee: "AA 约 30／人", tags: ["乒乓球", "运动搭子"], distanceKM: 5.5,
            participantNames: ["林夏", "Coco", "阿梨", "Yuna"],
            latitude: 31.2320, longitude: 121.5310
        ),
        Activity(
            id: uid(11), title: "烤肉无限畅吃", category: .food,
            location: "静安 · 南京西路烤肉店", date: day(1, hour: 18, minute: 30),
            capacity: 8, joined: 8, hostName: "面团",
            summary: "自助烤肉，已订位。已满，候补有人退出会私信。",
            fee: "人均约 128", tags: ["烤肉", "晚饭", "探店"], distanceKM: 1.0,
            participantNames: ["面团", "小周", "Mia", "Leo", "Noon", "阿禾", "Coco", "Yuna"],
            latitude: 31.2238, longitude: 121.4452
        ),
        Activity(
            id: uid(12), title: "健身房力量课拼团", category: .outdoorSports,
            location: "浦东 · 陆家嘴商业健身房", date: day(1, hour: 19),
            capacity: 10, joined: 6, hostName: "Yuna",
            summary: "团课体验名额，教练带练。自备运动服和毛巾。",
            fee: "体验约 49／人", tags: ["健身", "团课"], distanceKM: 6.8,
            participantNames: ["Yuna", "林夏", "Coco", "Leo", "Noon", "阿凯"],
            latitude: 31.2358, longitude: 121.5055
        ),
        Activity(
            id: uid(13), title: "剧本杀：情感本", category: .entertainment,
            location: "黄浦 · 人民广场剧本杀馆", date: day(4, hour: 14),
            capacity: 8, joined: 6, hostName: "推理阿哲",
            summary: "6–8 人情感本，新手友好。约 5 小时，馆内有简餐。",
            fee: "馆费约 128／人", tags: ["剧本杀", "周末"], distanceKM: 2.8,
            participantNames: ["推理阿哲", "Mia", "Coco", "小周", "Noon", "林夏"],
            latitude: 31.2310, longitude: 121.4740
        ),
        Activity(
            id: uid(14), title: "夜市小吃暴走", category: .food,
            location: "闵行 · 七宝老街北入口", date: day(5, hour: 17),
            capacity: 10, joined: 4, hostName: "老街阿成",
            summary: "晚饭靠小吃解决，边走边吃边拍照。预算自己控。",
            fee: "餐食自费", tags: ["夜市", "小吃", "探店"], distanceKM: 14.0,
            participantNames: ["老街阿成", "阿禾", "Noon", "小周"],
            latitude: 31.1520, longitude: 121.3490
        ),
        Activity(
            id: uid(15), title: "台球娱乐局", category: .entertainment,
            location: "徐汇 · 漕溪路台球室", date: day(2, hour: 20),
            capacity: 6, joined: 3, hostName: "Leo",
            summary: "中八娱乐，会打就行。台费 AA，可教新手。",
            fee: "台费 AA 约 40／人", tags: ["台球", "娱乐"], distanceKM: 4.1,
            participantNames: ["Leo", "Yuna", "阿凯"],
            latitude: 31.1835, longitude: 121.4395
        ),
        Activity(
            id: uid(16), title: "南京路步行街逛街", category: .cityExplore,
            location: "黄浦 · 地铁南京东路站集合", date: day(6, hour: 14),
            capacity: 12, joined: 7, hostName: "逛街阿可",
            summary: "逛街 + 探店 + 随便吃，不硬性购物。累了就找地方坐。",
            fee: "消费自理", tags: ["逛街", "探店", "周末"], distanceKM: 2.3,
            participantNames: ["逛街阿可", "Mia", "林夏", "Coco", "小周", "Noon", "阿梨"],
            latitude: 31.2350, longitude: 121.4800
        ),
        Activity(
            id: uid(17), title: "桌游局：狼人杀", category: .entertainment,
            location: "长宁 · 中山公园桌游吧", date: day(1, hour: 19, minute: 30),
            capacity: 12, joined: 8, hostName: "骰子阿北",
            summary: "会教规则，打 3–4 局。台费 AA，饮品自点。",
            fee: "台费约 35／人", tags: ["桌游", "狼人杀", "新手"], distanceKM: 5.2,
            participantNames: ["骰子阿北", "Coco", "小周", "Noon", "阿凯", "林夏", "Mia", "Yuna"],
            latitude: 31.2215, longitude: 121.4168
        ),
        Activity(
            id: uid(18), title: "保龄球新手局", category: .entertainment,
            location: "浦东 · 世纪汇保龄球馆", date: day(3, hour: 15),
            capacity: 8, joined: 4, hostName: "球馆阿南",
            summary: "两局起，鞋和球馆里有。纯娱乐，不比分。",
            fee: "约 60／人（含两局）", tags: ["保龄球", "周末"], distanceKM: 7.5,
            participantNames: ["球馆阿南", "林夏", "Coco", "小周"],
            latitude: 31.2200, longitude: 121.5400
        ),
        Activity(
            id: uid(19), title: "KTV 麦霸开唱", category: .entertainment,
            location: "黄浦 · 人民广场量贩 KTV", date: hours(30),
            capacity: 10, joined: 7, hostName: "麦旋风",
            summary: "订了中包 3 小时，歌单随意；不喝酒也欢迎。",
            fee: "AA 约 60／人（含小吃）", tags: ["KTV", "唱歌"], distanceKM: 2.8,
            participantNames: ["麦旋风", "Coco", "Noon", "小周", "Mia", "阿凯", "Yuna"],
            latitude: 31.2310, longitude: 121.4737
        ),
        Activity(
            id: uid(20), title: "密室逃脱拼队", category: .entertainment,
            location: "静安 · 南京西路密室馆", date: day(2, hour: 16),
            capacity: 6, joined: 4, hostName: "解密阿澄",
            summary: "机制馆 2 小时，缺人拼队。恐高慎入。",
            fee: "约 150／人", tags: ["密室逃脱", "周末"], distanceKM: 1.4,
            participantNames: ["解密阿澄", "阿凯", "Leo", "Coco"],
            latitude: 31.2270, longitude: 121.4520
        ),
        Activity(
            id: uid(21), title: "麻将娱乐局", category: .entertainment,
            location: "普陀 · 棋牌室（群内发）", date: day(4, hour: 14),
            capacity: 4, joined: 2, hostName: "雀神小满",
            summary: "上海规矩娱乐局，封顶友好。茶位费 AA。",
            fee: "茶位约 40／人", tags: ["麻将", "娱乐"], distanceKM: 5.5,
            participantNames: ["雀神小满", "小周"],
            latitude: 31.2478, longitude: 121.4425
        ),
        Activity(
            id: uid(22), title: "外滩夜景骑行拍照", category: .cityExplore,
            location: "浦东 · 东方明珠下滨江", date: day(0, hour: 19),
            capacity: 14, joined: 8, hostName: "日落阿川",
            summary: "夜景骑一段 + 打卡拍照，约 1.5 小时。骑行和步行都可。",
            fee: "免费", tags: ["夜游", "骑行", "拍照"], distanceKM: 7.0,
            participantNames: ["日落阿川", "林夏", "阿凯", "Noon", "Coco", "Yuna", "小周", "Leo"],
            latitude: 31.2397, longitude: 121.4998
        )
    ]

    // MARK: - Circles

    static let interestCircles: [InterestCircle] = [
        InterestCircle(id: uid(101), name: "黄浦夜骑群", topic: "骑行", city: "上海 · 黄浦",
                       memberCount: 286, weeklyActive: 48, tags: ["夜骑", "滨江", "入门友好"],
                       summary: "免费兴趣圈。工作日夜骑、周末轻局，分享路线和集合点。",
                       isJoined: true, systemImage: "bicycle"),
        InterestCircle(id: uid(102), name: "徐汇桌游群", topic: "娱乐", city: "上海 · 徐汇",
                       memberCount: 412, weeklyActive: 63, tags: ["桌游", "剧本杀", "KTV"],
                       summary: "周末桌游、剧本杀、KTV 自由组局，缺人来群里喊。",
                       isJoined: true, systemImage: "gamecontroller"),
        InterestCircle(id: uid(103), name: "松江徒步群", topic: "户外", city: "上海 · 松江",
                       memberCount: 198, weeklyActive: 31, tags: ["爬山", "徒步", "骑行"],
                       summary: "周末轻松户外，爬山骑行随缘组队。",
                       isJoined: false, systemImage: "figure.hiking"),
        InterestCircle(id: uid(104), name: "静安羽球群", topic: "运动", city: "上海 · 静安",
                       memberCount: 354, weeklyActive: 72, tags: ["羽毛球", "双打", "约场"],
                       summary: "水平相近自由开黑，群内互约场地。加入免费，场地费 AA。",
                       isJoined: false, systemImage: "figure.badminton"),
        InterestCircle(id: uid(105), name: "徐汇吃喝群", topic: "美食", city: "上海 · 徐汇",
                       memberCount: 521, weeklyActive: 89, tags: ["火锅局", "烧烤", "探店"],
                       summary: "交换好吃不贵清单，组火锅烧烤拼桌。",
                       isJoined: true, systemImage: "fork.knife"),
        InterestCircle(id: uid(106), name: "浦东夜跑群", topic: "运动", city: "上海 · 浦东",
                       memberCount: 167, weeklyActive: 40, tags: ["夜跑", "骑行"],
                       summary: "工作日夜跑夜骑，欢迎下班后来。",
                       isJoined: false, systemImage: "figure.run"),
        InterestCircle(id: uid(107), name: "黄浦探店群", topic: "玩乐", city: "上海 · 黄浦",
                       memberCount: 233, weeklyActive: 27, tags: ["逛街", "探店", "夜市"],
                       summary: "周末逛街吃吃逛逛，不硬性购物。",
                       isJoined: true, systemImage: "bag"),
        // 成都
        InterestCircle(id: uid(111), name: "锦江夜骑群", topic: "骑行", city: "成都 · 锦江",
                       memberCount: 312, weeklyActive: 55, tags: ["夜骑", "东湖", "入门友好"],
                       summary: "东湖 / 锦江夜骑，配速友好，欢迎第一次来的同好。",
                       isJoined: false, systemImage: "bicycle"),
        InterestCircle(id: uid(112), name: "武侯火锅群", topic: "美食", city: "成都 · 武侯",
                       memberCount: 486, weeklyActive: 91, tags: ["火锅", "串串", "探店"],
                       summary: "控辣、控预算拼桌，店单每周更新。",
                       isJoined: false, systemImage: "fork.knife"),
        InterestCircle(id: uid(113), name: "高新羽球群", topic: "运动", city: "成都 · 高新区",
                       memberCount: 268, weeklyActive: 64, tags: ["羽毛球", "双打", "约场"],
                       summary: "水平相近开黑，群内互约场馆。",
                       isJoined: false, systemImage: "figure.badminton"),
        InterestCircle(id: uid(114), name: "宽窄慢逛群", topic: "玩乐", city: "成都 · 青羊",
                       memberCount: 194, weeklyActive: 33, tags: ["漫步", "市集", "咖啡"],
                       summary: "宽窄 / 少城慢逛，拍照喝茶不赶场。",
                       isJoined: false, systemImage: "cup.and.saucer"),
        InterestCircle(id: uid(115), name: "龙泉徒步群", topic: "户外", city: "成都 · 龙泉驿",
                       memberCount: 221, weeklyActive: 38, tags: ["徒步", "看花", "露营"],
                       summary: "周末轻徒步，节奏慢，重点呼吸和拍照。",
                       isJoined: false, systemImage: "figure.hiking")
    ]

    // MARK: - Voice halls（陪玩页第二幕：语音厅，不对用户开放工会入会）

    static let voiceHalls: [VoiceHall] = [
        VoiceHall(
            id: uid(301), title: "夜骑配速厅", topic: "骑行",
            city: "上海 · 黄浦", hostNickname: "阿凯",
            onMicNicknames: ["阿凯", "Coco", "小周"],
            listenerCount: 128, tagline: "滨江夜骑闲聊，新手也可挂麦听听",
            systemImage: "bicycle", isLive: true
        ),
        VoiceHall(
            id: uid(302), title: "探店陪吃热麦", topic: "美食",
            city: "上海 · 徐汇", hostNickname: "小周",
            onMicNicknames: ["小周", "Mia"],
            listenerCount: 86, tagline: "今晚吃哪家，控预算现场报",
            systemImage: "fork.knife", isLive: true
        ),
        VoiceHall(
            id: uid(303), title: "羽球约场厅", topic: "运动",
            city: "上海 · 静安", hostNickname: "Yuna",
            onMicNicknames: ["Yuna", "Leo"],
            listenerCount: 54, tagline: "找固定搭子 / 轻度陪练咨询",
            systemImage: "figure.badminton", isLive: true
        ),
        VoiceHall(
            id: uid(304), title: "宽窄慢聊厅", topic: "漫步",
            city: "成都 · 青羊", hostNickname: "南栀",
            onMicNicknames: ["南栀", "江晚"],
            listenerCount: 72, tagline: "少城路线与拍照点实时聊",
            systemImage: "cup.and.saucer", isLive: true
        ),
        VoiceHall(
            id: uid(305), title: "火锅控辣厅", topic: "美食",
            city: "成都 · 武侯", hostNickname: "小满",
            onMicNicknames: ["小满", "木子", "老白"],
            listenerCount: 163, tagline: "串串拼桌、控辣控油现场报店",
            systemImage: "flame", isLive: true
        ),
        VoiceHall(
            id: uid(306), title: "东湖夜骑厅", topic: "骑行",
            city: "成都 · 锦江", hostNickname: "阿川",
            onMicNicknames: ["阿川"],
            listenerCount: 41, tagline: "今晚有局就上麦，没有就听听路线",
            systemImage: "bicycle", isLive: false
        )
    ]

    // MARK: - Companion guilds（供给侧标签，不对用户开放入会）

    static let companionGuilds: [CompanionGuild] = [
        CompanionGuild(
            id: uid(201), name: "夜骑领队工会", specialty: "骑行陪玩",
            city: "上海 · 黄浦", companionCount: 28, weeklyOrders: 64,
            priceFrom: 128, tags: ["夜骑", "入门", "领队"],
            summary: "认证夜骑领队，路线规划与配速陪跑，按时计费。",
            isJoined: true, systemImage: "bicycle"
        ),
        CompanionGuild(
            id: uid(202), name: "探店陪吃社", specialty: "线下陪玩",
            city: "上海 · 徐汇", companionCount: 41, weeklyOrders: 92,
            priceFrom: 138, tags: ["探店", "美食", "陪吃"],
            summary: "熟门熟路陪吃陪逛，控预算不劝酒。",
            isJoined: false, systemImage: "fork.knife"
        ),
        CompanionGuild(
            id: uid(203), name: "剧本杀主持人联盟", specialty: "活动陪玩",
            city: "上海 · 静安", companionCount: 19, weeklyOrders: 37,
            priceFrom: 158, tags: ["剧本杀", "主持", "开黑"],
            summary: "资深主持人驻场，可约整场或补位。",
            isJoined: true, systemImage: "theatermasks"
        ),
        CompanionGuild(
            id: uid(204), name: "夜跑陪跑站", specialty: "运动陪玩",
            city: "上海 · 普陀", companionCount: 22, weeklyOrders: 51,
            priceFrom: 118, tags: ["夜跑", "拉伸", "陪跑"],
            summary: "按配速分组陪跑，跑后拉伸指导。",
            isJoined: false, systemImage: "figure.run"
        ),
        CompanionGuild(
            id: uid(205), name: "展览讲解小分队", specialty: "文化陪玩",
            city: "上海 · 黄浦", companionCount: 15, weeklyOrders: 29,
            priceFrom: 148, tags: ["展览", "讲解", "拍照"],
            summary: "策展向讲解 + 出片指导，适合周末展览。",
            isJoined: false, systemImage: "building.columns"
        ),
        // 成都
        CompanionGuild(
            id: uid(211), name: "锦江夜骑领队会", specialty: "骑行陪玩",
            city: "成都 · 锦江", companionCount: 24, weeklyOrders: 58,
            priceFrom: 118, tags: ["夜骑", "东湖", "领队"],
            summary: "认证夜骑领队，东湖 / 锦江配速陪骑。",
            isJoined: false, systemImage: "bicycle"
        ),
        CompanionGuild(
            id: uid(212), name: "成都火锅陪吃社", specialty: "线下陪玩",
            city: "成都 · 武侯", companionCount: 36, weeklyOrders: 81,
            priceFrom: 128, tags: ["火锅", "串串", "陪吃"],
            summary: "熟门熟路陪吃，帮你控辣控预算。",
            isJoined: false, systemImage: "fork.knife"
        ),
        CompanionGuild(
            id: uid(213), name: "高新羽球陪练站", specialty: "运动陪玩",
            city: "成都 · 高新区", companionCount: 18, weeklyOrders: 44,
            priceFrom: 158, tags: ["羽毛球", "陪练", "纠正"],
            summary: "约场陪练与轻度技术纠正，场地费另计。",
            isJoined: false, systemImage: "figure.badminton"
        ),
        CompanionGuild(
            id: uid(214), name: "少城漫步讲解社", specialty: "文化陪玩",
            city: "成都 · 青羊", companionCount: 14, weeklyOrders: 27,
            priceFrom: 138, tags: ["漫步", "历史", "拍照"],
            summary: "宽窄 / 少城路线讲解 + 出片点位。",
            isJoined: false, systemImage: "building.columns"
        )
    ]

    // MARK: - Buddies

    private static let buddyDemoPhotoAssets = [
        "BuddyDemoPhoto1",
        "BuddyDemoPhoto2",
        "BuddyDemoPhoto3"
    ]

    private static func buddy(
        nick: String, gender: BuddyGender, age: Int, h: Int, w: Int, km: Double,
        seeds: [Int], city: String, bio: String, tags: [String],
        avail: String, active: String, looking: String,
        photoAssets: [String] = []
    ) -> BuddyProfile {
        BuddyProfile(
            id: UUID(), nickname: nick, gender: gender, age: age,
            heightCM: h, weightKG: w, distanceKM: km, photoSeeds: seeds,
            photoAssetNames: photoAssets,
            city: city, bio: bio, tags: tags, availability: avail,
            lastActiveText: active, lookingFor: looking
        )
    }

    static let circleBuddies: [CircleBuddy] = [
        // 置顶：三张本地实拍，方便舞台看 Hero / 多图翻页效果
        CircleBuddy(
            profile: buddy(nick: "Mia", gender: .female, age: 25, h: 165, w: 48, km: 1.6,
                           seeds: [], city: "上海 · 徐汇",
                           bio: "常出没于小展和独立书店，也喜欢安静的咖啡聊天。",
                           tags: ["骑行", "展览", "市集"], avail: "本周六下午", active: "2 小时前活跃", looking: "想找咖啡漫谈",
                           photoAssets: buddyDemoPhotoAssets),
            circleName: "徐汇桌游群", topic: "社交", isOnline: false,
            scheduleSlots: ["周六 14:00", "周日 15:00"],
            reviews: [BuddyReview(id: UUID(), author: "林夏", rating: 5, comment: "聊天舒服，选店也很有品位。", dateText: "5 天前")],
            relatedActivityTitles: ["思南公馆咖啡漫谈", "安福路独立书店半日"]
        ),
        CircleBuddy(
            profile: buddy(nick: "阿凯", gender: .male, age: 27, h: 178, w: 70, km: 0.8,
                           seeds: [1011, 1012, 1015], city: "上海 · 黄浦",
                           bio: "夜骑爱好者，喜欢轻松局和城市探索，欢迎同好一起出发。",
                           tags: ["骑行", "摄影", "咖啡"], avail: "今晚可约", active: "刚刚活跃", looking: "想找夜骑局",
                           photoAssets: buddyDemoPhotoAssets),
            circleName: "黄浦夜骑群", topic: "骑行", isOnline: true,
            scheduleSlots: ["今晚 20:00", "周五 21:00", "周六上午"],
            reviews: [
                BuddyReview(id: UUID(), author: "林屿", rating: 5, comment: "带队稳，新手也很安心。", dateText: "3 天前"),
                BuddyReview(id: UUID(), author: "小周", rating: 5, comment: "路线讲解清楚，节奏刚好。", dateText: "1 周前")
            ],
            relatedActivityTitles: ["外滩夜骑轻态局"]
        ),
        CircleBuddy(
            profile: buddy(nick: "阿禾", gender: .male, age: 29, h: 175, w: 68, km: 12.4,
                           seeds: [1043, 1044, 1050], city: "上海 · 松江",
                           bio: "偏好不卷的户外，重点是呼吸新鲜空气和拍树。",
                           tags: ["徒步", "露营", "植物"], avail: "周日全天", active: "今天活跃", looking: "想找轻徒步"),
            circleName: "松江徒步群", topic: "户外", isOnline: true,
            scheduleSlots: ["周日 09:00", "下周六全天"],
            reviews: [BuddyReview(id: UUID(), author: "Yuna", rating: 4, comment: "节奏慢，适合放松。", dateText: "2 周前")],
            relatedActivityTitles: ["辰山植物园轻徒步"]
        ),
        CircleBuddy(
            profile: buddy(nick: "小周", gender: .male, age: 26, h: 172, w: 65, km: 2.3,
                           seeds: [1060, 1069, 1074], city: "上海 · 静安",
                           bio: "吃货但控预算，欢迎一起做区域美食攻略。",
                           tags: ["美食", "夜市", "纪录片"], avail: "周五晚饭后", active: "30 分钟前活跃", looking: "想找探店局"),
            circleName: "徐汇吃喝群", topic: "美食", isOnline: true,
            scheduleSlots: ["周五 18:30", "周六 12:00"],
            reviews: [BuddyReview(id: UUID(), author: "阿凯", rating: 5, comment: "路线扎实，人均控制得好。", dateText: "4 天前")],
            relatedActivityTitles: ["武康路美食散打"]
        ),
        CircleBuddy(
            profile: buddy(nick: "Yuna", gender: .female, age: 24, h: 168, w: 52, km: 5.1,
                           seeds: [1084, 129, 177], city: "上海 · 浦东",
                           bio: "寻找长期固定运动搭子，时间灵活可约工作日晚饭后。",
                           tags: ["羽毛球", "网球", "拉伸"], avail: "工作日 19:00 后", active: "昨天活跃", looking: "想找羽毛球搭档"),
            circleName: "静安羽球群", topic: "运动", isOnline: false,
            scheduleSlots: ["周一 19:30", "周三 19:30", "周五 20:00"],
            reviews: [BuddyReview(id: UUID(), author: "Leo", rating: 5, comment: "打法干净，很适合固定搭子。", dateText: "1 周前")],
            relatedActivityTitles: ["羽毛球混双打野", "陆家嘴晨间拉伸局"]
        ),
        CircleBuddy(
            profile: buddy(nick: "林夏", gender: .female, age: 28, h: 162, w: 50, km: 3.7,
                           seeds: [201, 202, 219], city: "上海 · 徐汇",
                           bio: "周末爱逛市集和手作摊，也愿意当新人向导。",
                           tags: ["市集", "手作", "摄影"], avail: "本周末可约", active: "1 小时前活跃", looking: "想逛周末市集"),
            circleName: "徐汇桌游群", topic: "社交", isOnline: true,
            scheduleSlots: ["周六全天", "周日下午"],
            reviews: [BuddyReview(id: UUID(), author: "Mia", rating: 5, comment: "拍照点找得很准。", dateText: "6 天前")],
            relatedActivityTitles: ["徐汇滨江市集漫逛", "世纪公园野餐拍照"]
        ),
        CircleBuddy(
            profile: buddy(nick: "Leo", gender: .male, age: 30, h: 182, w: 74, km: 1.4,
                           seeds: [220, 221, 222], city: "上海 · 静安",
                           bio: "羽毛球 / 网球都玩，喜欢固定局而不是临时局。",
                           tags: ["羽毛球", "网球", "拉伸"], avail: "今晚可约", active: "刚刚活跃", looking: "想找混双打野"),
            circleName: "静安羽球群", topic: "运动", isOnline: true,
            scheduleSlots: ["今晚 20:00", "周四 19:30"],
            reviews: [BuddyReview(id: UUID(), author: "Yuna", rating: 5, comment: "约场准时，球商好。", dateText: "2 天前")],
            relatedActivityTitles: ["羽毛球混双打野", "网球入门对打"]
        ),
        CircleBuddy(
            profile: buddy(nick: "Noon", gender: .female, age: 27, h: 170, w: 55, km: 4.2,
                           seeds: [230, 231, 232], city: "上海 · 普陀",
                           bio: "夜跑与城市散步组织者，配速友好，欢迎第一次来的朋友。",
                           tags: ["跑步", "建筑", "咖啡"], avail: "今晚 19:30", active: "今天活跃", looking: "想找夜跑搭子"),
            circleName: "黄浦探店群", topic: "文化", isOnline: true,
            scheduleSlots: ["今晚 19:30", "周六 10:00"],
            reviews: [BuddyReview(id: UUID(), author: "阿凯", rating: 5, comment: "节奏稳，路线讲解有趣。", dateText: "1 周前")],
            relatedActivityTitles: ["苏州河夜跑 5K", "衡复历史建筑散步"]
        ),
        CircleBuddy(
            profile: buddy(nick: "Coco", gender: .female, age: 23, h: 160, w: 46, km: 2.9,
                           seeds: [240, 241, 242], city: "上海 · 黄浦",
                           bio: "喜欢市集淘物和胶片感拍照，也可陪新人第一次组局。",
                           tags: ["摄影", "市集", "咖啡"], avail: "本周日", active: "3 小时前活跃", looking: "想找拍照搭子"),
            circleName: "黄浦夜骑群", topic: "骑行", isOnline: false,
            scheduleSlots: ["周日下午", "下周六"],
            reviews: [BuddyReview(id: UUID(), author: "林夏", rating: 5, comment: "构图很会，人超好。", dateText: "4 天前")],
            relatedActivityTitles: ["外滩夜骑轻态局"]
        ),
        CircleBuddy(
            profile: buddy(nick: "阿哲", gender: .male, age: 31, h: 176, w: 72, km: 7.5,
                           seeds: [250, 251, 252], city: "上海 · 浦东",
                           bio: "晨练拉伸与轻力量，适合上班族早晨空档。",
                           tags: ["拉伸", "跑步", "咖啡"], avail: "明早 7:30", active: "昨天活跃", looking: "想找晨练搭子"),
            circleName: "浦东夜跑群", topic: "运动", isOnline: false,
            scheduleSlots: ["明早 7:30", "周五 7:30"],
            reviews: [BuddyReview(id: UUID(), author: "Yuna", rating: 4, comment: "动作讲解清楚。", dateText: "1 周前")],
            relatedActivityTitles: ["陆家嘴晨间拉伸局"]
        ),
        // MARK: 成都同好
        CircleBuddy(
            profile: buddy(nick: "阿川", gender: .male, age: 28, h: 180, w: 72, km: 1.2,
                           seeds: [601, 602, 605], city: "成都 · 锦江",
                           bio: "东湖夜骑常客，配速稳，也爱路边摊收尾。",
                           tags: ["骑行", "摄影", "美食"], avail: "今晚可约", active: "刚刚活跃", looking: "想找夜骑局"),
            circleName: "锦江夜骑群", topic: "骑行", isOnline: true,
            scheduleSlots: ["今晚 20:00", "周五 21:00", "周六上午"],
            reviews: [
                BuddyReview(id: UUID(), author: "小满", rating: 5, comment: "带队清楚，新手也跟得上。", dateText: "2 天前")
            ],
            relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "小满", gender: .female, age: 24, h: 163, w: 47, km: 2.1,
                           seeds: [610, 611, 618], city: "成都 · 武侯",
                           bio: "火锅控辣选手，擅长按预算拼桌，周末爱逛玉林。",
                           tags: ["美食", "咖啡", "市集"], avail: "周五晚饭后", active: "30 分钟前活跃", looking: "想找火锅拼桌"),
            circleName: "武侯火锅群", topic: "美食", isOnline: true,
            scheduleSlots: ["周五 18:30", "周六 12:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "叙叙", rating: 5, comment: "店选得准，人均也好控。", dateText: "4 天前")
            ],
            relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "叙叙", gender: .female, age: 26, h: 166, w: 50, km: 3.4,
                           seeds: [620, 621, 629], city: "成都 · 高新区",
                           bio: "羽毛球固搭招募中，工作日晚饭后时间灵活。",
                           tags: ["羽毛球", "拉伸", "咖啡"], avail: "工作日 19:00 后", active: "今天活跃", looking: "想找羽毛球搭档"),
            circleName: "高新羽球群", topic: "运动", isOnline: false,
            scheduleSlots: ["周一 19:30", "周三 19:30", "周五 20:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "老白", rating: 5, comment: "打法干净，约场准时。", dateText: "1 周前")
            ],
            relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "南栀", gender: .female, age: 27, h: 168, w: 52, km: 1.8,
                           seeds: [630, 631, 640], city: "成都 · 青羊",
                           bio: "宽窄慢逛与独立咖啡馆常客，也愿意当新人向导。",
                           tags: ["展览", "咖啡", "摄影"], avail: "本周末可约", active: "1 小时前活跃", looking: "想找慢逛搭子"),
            circleName: "宽窄慢逛群", topic: "玩乐", isOnline: true,
            scheduleSlots: ["周六下午", "周日 15:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "青禾", rating: 5, comment: "节奏舒服，拍照点很会找。", dateText: "5 天前")
            ],
            relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "老白", gender: .male, age: 30, h: 176, w: 70, km: 4.6,
                           seeds: [650, 651, 655], city: "成都 · 成华",
                           bio: "夜跑配速友好，跑后爱找串串收尾。",
                           tags: ["跑步", "美食", "拉伸"], avail: "今晚 19:30", active: "今天活跃", looking: "想找夜跑搭子"),
            circleName: "锦江夜骑群", topic: "运动", isOnline: true,
            scheduleSlots: ["今晚 19:30", "周六 10:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "阿川", rating: 5, comment: "配速稳，路线讲解有趣。", dateText: "3 天前")
            ],
            relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "青禾", gender: .female, age: 25, h: 161, w: 48, km: 8.2,
                           seeds: [660, 661, 668], city: "成都 · 龙泉驿",
                           bio: "龙泉山轻徒步与看花局，节奏慢，重点拍照和透气。",
                           tags: ["徒步", "摄影", "露营"], avail: "周日全天", active: "昨天活跃", looking: "想找轻徒步"),
            circleName: "龙泉徒步群", topic: "户外", isOnline: false,
            scheduleSlots: ["周日 09:00", "下周六全天"],
            reviews: [
                BuddyReview(id: UUID(), author: "木子", rating: 4, comment: "不卷，适合放松。", dateText: "2 周前")
            ],
            relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "木子", gender: .male, age: 29, h: 174, w: 68, km: 2.7,
                           seeds: [670, 671, 679], city: "成都 · 金牛",
                           bio: "桌游 / 剧本杀缺人就喊，也爱茶馆摆龙门阵。",
                           tags: ["桌游", "咖啡", "市集"], avail: "本周六下午", active: "2 小时前活跃", looking: "想找开黑局"),
            circleName: "宽窄慢逛群", topic: "娱乐", isOnline: true,
            scheduleSlots: ["周六 14:00", "周日 15:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "江晚", rating: 5, comment: "局风轻松，新人很友好。", dateText: "6 天前")
            ],
            relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "江晚", gender: .female, age: 23, h: 158, w: 45, km: 3.1,
                           seeds: [680, 681, 690], city: "成都 · 武侯",
                           bio: "市集淘物与胶片感拍照，也可陪第一次组局。",
                           tags: ["摄影", "市集", "咖啡"], avail: "本周日", active: "3 小时前活跃", looking: "想找拍照搭子"),
            circleName: "武侯火锅群", topic: "社交", isOnline: false,
            scheduleSlots: ["周日下午", "下周六"],
            reviews: [
                BuddyReview(id: UUID(), author: "南栀", rating: 5, comment: "构图很会，人超好处。", dateText: "4 天前")
            ],
            relatedActivityTitles: []
        ),
        // MARK: 上海同好扩充（网格密度）
        CircleBuddy(
            profile: buddy(nick: "北辰", gender: .male, age: 28, h: 179, w: 71, km: 1.1,
                           seeds: [1101, 1102, 1103], city: "上海 · 黄浦",
                           bio: "周末滨江骑行，也爱咖啡收尾。",
                           tags: ["骑行", "咖啡", "摄影"], avail: "周六上午", active: "刚刚活跃", looking: "想找骑行搭子"),
            circleName: "黄浦夜骑群", topic: "骑行", isOnline: true,
            scheduleSlots: ["周六 09:00", "周日 16:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "半夏", gender: .female, age: 26, h: 164, w: 49, km: 2.0,
                           seeds: [1111, 1112, 1113], city: "上海 · 徐汇",
                           bio: "桌游规则能教，剧本杀也欢迎新人。",
                           tags: ["桌游", "剧本杀", "咖啡"], avail: "本周六下午", active: "1 小时前活跃", looking: "想找开黑局"),
            circleName: "徐汇桌游群", topic: "娱乐", isOnline: true,
            scheduleSlots: ["周六 14:00", "周日 15:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "青杉", gender: .male, age: 32, h: 177, w: 73, km: 9.8,
                           seeds: [1121, 1122, 1123], city: "上海 · 松江",
                           bio: "佘山轻松线常客，不卷配速。",
                           tags: ["徒步", "摄影", "露营"], avail: "周日全天", active: "今天活跃", looking: "想找轻徒步"),
            circleName: "松江徒步群", topic: "户外", isOnline: false,
            scheduleSlots: ["周日 09:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "柚子", gender: .female, age: 24, h: 161, w: 47, km: 1.9,
                           seeds: [1131, 1132, 1133], city: "上海 · 静安",
                           bio: "羽毛球 2.5～3.0，固定局优先。",
                           tags: ["羽毛球", "拉伸", "网球"], avail: "今晚可约", active: "30 分钟前活跃", looking: "想找羽球搭档"),
            circleName: "静安羽球群", topic: "运动", isOnline: true,
            scheduleSlots: ["今晚 20:00", "周三 19:30"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "老陈", gender: .male, age: 33, h: 174, w: 69, km: 3.2,
                           seeds: [1141, 1142, 1143], city: "上海 · 徐汇",
                           bio: "控预算探店，火锅烧烤都行。",
                           tags: ["美食", "夜市", "探店"], avail: "周五晚饭后", active: "今天活跃", looking: "想找探店局"),
            circleName: "徐汇吃喝群", topic: "美食", isOnline: false,
            scheduleSlots: ["周五 18:30", "周六 12:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "安安", gender: .female, age: 22, h: 159, w: 45, km: 4.5,
                           seeds: [1151, 1152, 1153], city: "上海 · 浦东",
                           bio: "夜跑配速友好，跑后拉伸。",
                           tags: ["跑步", "拉伸", "咖啡"], avail: "今晚 19:30", active: "刚刚活跃", looking: "想找夜跑搭子"),
            circleName: "浦东夜跑群", topic: "运动", isOnline: true,
            scheduleSlots: ["今晚 19:30", "周五 19:30"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "阿梨", gender: .female, age: 29, h: 167, w: 53, km: 2.4,
                           seeds: [1161, 1162, 1163], city: "上海 · 黄浦",
                           bio: "逛街探店不硬性购物，累了就坐。",
                           tags: ["逛街", "探店", "摄影"], avail: "本周末可约", active: "2 小时前活跃", looking: "想找逛街搭子"),
            circleName: "黄浦探店群", topic: "玩乐", isOnline: true,
            scheduleSlots: ["周六下午", "周日 14:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "言午", gender: .male, age: 27, h: 181, w: 75, km: 6.0,
                           seeds: [1171, 1172, 1173], city: "上海 · 浦东",
                           bio: "网球入门对打，也可混打羽毛球。",
                           tags: ["网球", "羽毛球", "拉伸"], avail: "工作日 19:00 后", active: "昨天活跃", looking: "想找运动固搭"),
            circleName: "静安羽球群", topic: "运动", isOnline: false,
            scheduleSlots: ["周一 19:30", "周四 19:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "小满满", gender: .female, age: 25, h: 163, w: 48, km: 3.8,
                           seeds: [1181, 1182, 1183], city: "上海 · 长宁",
                           bio: "市集手作摊常客，也拍胶片感照片。",
                           tags: ["市集", "手作", "摄影"], avail: "本周日", active: "今天活跃", looking: "想逛周末市集"),
            circleName: "徐汇桌游群", topic: "社交", isOnline: true,
            scheduleSlots: ["周日下午"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "禾川", gender: .male, age: 30, h: 176, w: 70, km: 5.6,
                           seeds: [1191, 1192, 1193], city: "上海 · 普陀",
                           bio: "城市散步与建筑打卡，配速聊天。",
                           tags: ["跑步", "建筑", "咖啡"], avail: "周六上午", active: "3 小时前活跃", looking: "想找散步搭子"),
            circleName: "黄浦探店群", topic: "文化", isOnline: false,
            scheduleSlots: ["周六 10:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "苏苏", gender: .female, age: 27, h: 165, w: 50, km: 1.3,
                           seeds: [1201, 1202, 1203], city: "上海 · 静安",
                           bio: "奶茶探店与轻松聊天局。",
                           tags: ["探店", "咖啡", "展览"], avail: "今晚可约", active: "刚刚活跃", looking: "想找聊天局"),
            circleName: "徐汇吃喝群", topic: "社交", isOnline: true,
            scheduleSlots: ["今晚 19:00", "周五 20:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "阿白", gender: .male, age: 26, h: 173, w: 66, km: 4.1,
                           seeds: [1211, 1212, 1213], city: "上海 · 黄浦",
                           bio: "夜骑续摊局常客，配速能聊天。",
                           tags: ["骑行", "夜市", "摄影"], avail: "周五晚上", active: "今天活跃", looking: "想找夜骑局"),
            circleName: "黄浦夜骑群", topic: "骑行", isOnline: true,
            scheduleSlots: ["周五 21:00", "周六 20:00"],
            reviews: [], relatedActivityTitles: []
        ),
        // MARK: 成都同好扩充
        CircleBuddy(
            profile: buddy(nick: "豆豆", gender: .female, age: 24, h: 160, w: 46, km: 2.2,
                           seeds: [1301, 1302, 1303], city: "成都 · 武侯",
                           bio: "玉林串串与火锅拼桌，控辣控油。",
                           tags: ["美食", "火锅", "市集"], avail: "周五晚饭后", active: "1 小时前活跃", looking: "想找拼桌"),
            circleName: "武侯火锅群", topic: "美食", isOnline: true,
            scheduleSlots: ["周五 18:30"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "阿泽", gender: .male, age: 29, h: 178, w: 72, km: 1.5,
                           seeds: [1311, 1312, 1313], city: "成都 · 锦江",
                           bio: "东湖夜骑，也可周末白天骑。",
                           tags: ["骑行", "摄影", "跑步"], avail: "今晚可约", active: "刚刚活跃", looking: "想找夜骑局"),
            circleName: "锦江夜骑群", topic: "骑行", isOnline: true,
            scheduleSlots: ["今晚 20:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "禾禾", gender: .female, age: 26, h: 165, w: 51, km: 3.0,
                           seeds: [1321, 1322, 1323], city: "成都 · 高新区",
                           bio: "羽毛球双打招募，水平相近优先。",
                           tags: ["羽毛球", "拉伸", "咖啡"], avail: "工作日 19:00 后", active: "今天活跃", looking: "想找羽球搭档"),
            circleName: "高新羽球群", topic: "运动", isOnline: false,
            scheduleSlots: ["周二 19:30", "周四 19:30"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "清清", gender: .female, age: 28, h: 168, w: 52, km: 2.6,
                           seeds: [1331, 1332, 1333], city: "成都 · 青羊",
                           bio: "宽窄慢逛与独立咖啡馆。",
                           tags: ["咖啡", "展览", "摄影"], avail: "本周末可约", active: "2 小时前活跃", looking: "想找慢逛搭子"),
            circleName: "宽窄慢逛群", topic: "玩乐", isOnline: true,
            scheduleSlots: ["周六下午"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "石头", gender: .male, age: 31, h: 175, w: 74, km: 7.5,
                           seeds: [1341, 1342, 1343], city: "成都 · 龙泉驿",
                           bio: "龙泉看花与轻徒步，节奏慢。",
                           tags: ["徒步", "摄影", "露营"], avail: "周日全天", active: "昨天活跃", looking: "想找轻徒步"),
            circleName: "龙泉徒步群", topic: "户外", isOnline: false,
            scheduleSlots: ["周日 09:00"],
            reviews: [], relatedActivityTitles: []
        ),
        CircleBuddy(
            profile: buddy(nick: "橙子", gender: .female, age: 23, h: 158, w: 44, km: 4.0,
                           seeds: [1351, 1352, 1353], city: "成都 · 金牛",
                           bio: "桌游缺人就喊，茶馆也能聊。",
                           tags: ["桌游", "咖啡", "市集"], avail: "本周六下午", active: "今天活跃", looking: "想找开黑局"),
            circleName: "宽窄慢逛群", topic: "娱乐", isOnline: true,
            scheduleSlots: ["周六 14:00"],
            reviews: [], relatedActivityTitles: []
        )
    ]

    static let paidCompanions: [PaidCompanion] = [
        PaidCompanion(
            profile: buddy(nick: "阿凯", gender: .male, age: 27, h: 178, w: 70, km: 0.8,
                           seeds: [301, 302, 306], city: "上海 · 黄浦",
                           bio: "可按你的节奏定制滨江/外滩骑行陪玩，含路线讲解与安全提醒。",
                           tags: ["骑行", "路线规划", "新手友好"], avail: "今日可约", active: "在线", looking: "可接夜骑陪玩"),
            serviceType: .activity, specialty: "夜骑领队 / 城市骑行陪玩",
            hourlyPrice: 128, rating: 4.9, orderCount: 126, isAvailable: true,
            responseTime: "通常 10 分钟内",
            scheduleSlots: ["今日 20:00", "明日 19:00", "周六 21:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "匿名用户", rating: 5, comment: "第一次夜骑就很安心。", dateText: "2 天前"),
                BuddyReview(id: UUID(), author: "Coco", rating: 5, comment: "讲解细致，性价比高。", dateText: "1 周前")
            ],
            relatedActivityTitles: ["外滩夜骑轻态局"]
        ),
        PaidCompanion(
            profile: buddy(nick: "Yuna", gender: .female, age: 24, h: 168, w: 52, km: 5.1,
                           seeds: [338, 349, 365], city: "上海 · 浦东",
                           bio: "提供约场陪练与轻度技术指导，可单次也可包周。场地费另计。",
                           tags: ["羽毛球", "陪练", "纠正动作"], avail: "明日 18:00 后", active: "今天活跃", looking: "可接羽毛球陪练"),
            serviceType: .activity, specialty: "羽毛球陪练",
            hourlyPrice: 168, rating: 4.8, orderCount: 89, isAvailable: true,
            responseTime: "通常 30 分钟内",
            scheduleSlots: ["明日 18:30", "周四 19:00"],
            reviews: [BuddyReview(id: UUID(), author: "阿凯", rating: 5, comment: "陪练专注，动作提醒及时。", dateText: "3 天前")],
            relatedActivityTitles: ["羽毛球混双打野"]
        ),
        PaidCompanion(
            profile: buddy(nick: "Mia", gender: .female, age: 25, h: 165, w: 48, km: 1.6,
                           seeds: [372, 399, 433], city: "上海 · 徐汇",
                           bio: "陪你逛展、市集和独立书店，按兴趣路线规划，适合不想独自逛的周末。",
                           tags: ["展览", "市集", "拍照点"], avail: "档期已满", active: "昨天活跃", looking: "本周档期已满"),
            serviceType: .offline, specialty: "展览 / 市集线下陪逛",
            hourlyPrice: 148, rating: 4.9, orderCount: 74, isAvailable: false,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["下周六待开放"],
            reviews: [BuddyReview(id: UUID(), author: "林夏", rating: 5, comment: "路线很会拍，体验完整。", dateText: "5 天前")],
            relatedActivityTitles: ["徐汇滨江市集漫逛"]
        ),
        PaidCompanion(
            profile: buddy(nick: "阿禾", gender: .male, age: 29, h: 175, w: 68, km: 12.4,
                           seeds: [447, 453, 491], city: "上海 · 松江",
                           bio: "一对一或小团线下陪走，含集合指引与轻松讲解。门票与交通自理。",
                           tags: ["徒步", "野餐", "植物科普"], avail: "本周日可约", active: "今天活跃", looking: "可接轻徒步向导"),
            serviceType: .offline, specialty: "轻徒步线下向导",
            hourlyPrice: 158, rating: 4.7, orderCount: 52, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["周日 09:00", "下周日 09:00"],
            reviews: [BuddyReview(id: UUID(), author: "匿名用户", rating: 4, comment: "讲解轻松，适合野餐节奏。", dateText: "1 周前")],
            relatedActivityTitles: ["辰山植物园轻徒步"]
        ),
        PaidCompanion(
            profile: buddy(nick: "小周", gender: .male, age: 26, h: 172, w: 65, km: 2.3,
                           seeds: [513, 528, 550], city: "上海 · 静安",
                           bio: "按预算定制街区美食路线，陪逛陪拍，消费各自买单，服务费按小时计。",
                           tags: ["探店", "预算控局", "夜市"], avail: "今晚可约", active: "刚刚活跃", looking: "可接探店陪吃"),
            serviceType: .offline, specialty: "美食探店陪吃",
            hourlyPrice: 138, rating: 4.8, orderCount: 103, isAvailable: true,
            responseTime: "通常 15 分钟内",
            scheduleSlots: ["今晚 18:30", "周六 12:00"],
            reviews: [BuddyReview(id: UUID(), author: "Mia", rating: 5, comment: "预算控得好，店也扎实。", dateText: "4 天前")],
            relatedActivityTitles: ["武康路美食散打"]
        ),
        PaidCompanion(
            profile: buddy(nick: "Noon", gender: .female, age: 27, h: 170, w: 55, km: 4.2,
                           seeds: [560, 561, 562], city: "上海 · 普陀",
                           bio: "夜跑陪跑与拉伸指导，可按配速分组。",
                           tags: ["跑步", "拉伸", "陪跑"], avail: "今晚可约", active: "在线", looking: "可接夜跑陪跑"),
            serviceType: .activity, specialty: "夜跑陪跑",
            hourlyPrice: 118, rating: 4.8, orderCount: 61, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["今晚 19:30", "周五 19:30"],
            reviews: [BuddyReview(id: UUID(), author: "Leo", rating: 5, comment: "配速稳，拉伸也很到位。", dateText: "3 天前")],
            relatedActivityTitles: ["苏州河夜跑 5K"]
        ),
        PaidCompanion(
            profile: buddy(nick: "林夏", gender: .female, age: 28, h: 162, w: 50, km: 3.7,
                           seeds: [570, 571, 572], city: "上海 · 徐汇",
                           bio: "市集 / 野餐拍照陪拍，出图快，可按风格沟通。",
                           tags: ["摄影", "市集", "陪拍"], avail: "周末可约", active: "今天活跃", looking: "可接陪拍"),
            serviceType: .offline, specialty: "市集陪拍",
            hourlyPrice: 158, rating: 4.9, orderCount: 47, isAvailable: true,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["周六下午", "周日上午"],
            reviews: [BuddyReview(id: UUID(), author: "Coco", rating: 5, comment: "出片自然，沟通顺。", dateText: "5 天前")],
            relatedActivityTitles: ["世纪公园野餐拍照"]
        ),
        // MARK: 成都陪玩
        PaidCompanion(
            profile: buddy(nick: "阿川", gender: .male, age: 28, h: 180, w: 72, km: 1.2,
                           seeds: [701, 702, 708], city: "成都 · 锦江",
                           bio: "东湖 / 锦江夜骑陪玩，含路线讲解与安全提醒，可按配速定制。",
                           tags: ["骑行", "路线规划", "新手友好"], avail: "今日可约", active: "在线", looking: "可接夜骑陪玩"),
            serviceType: .activity, specialty: "夜骑领队 / 城市骑行陪玩",
            hourlyPrice: 118, rating: 4.9, orderCount: 96, isAvailable: true,
            responseTime: "通常 10 分钟内",
            scheduleSlots: ["今日 20:00", "明日 19:00", "周六 21:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "匿名用户", rating: 5, comment: "第一次夜骑很安心。", dateText: "2 天前"),
                BuddyReview(id: UUID(), author: "江晚", rating: 5, comment: "讲解细致，性价比高。", dateText: "1 周前")
            ],
            relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "叙叙", gender: .female, age: 26, h: 166, w: 50, km: 3.4,
                           seeds: [710, 711, 720], city: "成都 · 高新区",
                           bio: "羽毛球约场陪练与轻度技术纠正，可单次也可包周。场地费另计。",
                           tags: ["羽毛球", "陪练", "纠正动作"], avail: "明日 18:00 后", active: "今天活跃", looking: "可接羽毛球陪练"),
            serviceType: .activity, specialty: "羽毛球陪练",
            hourlyPrice: 158, rating: 4.8, orderCount: 72, isAvailable: true,
            responseTime: "通常 30 分钟内",
            scheduleSlots: ["明日 18:30", "周四 19:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "老白", rating: 5, comment: "陪练专注，提醒及时。", dateText: "3 天前")
            ],
            relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "小满", gender: .female, age: 24, h: 163, w: 47, km: 2.1,
                           seeds: [730, 731, 740], city: "成都 · 武侯",
                           bio: "按预算定制火锅 / 串串路线，陪吃陪逛，消费各自买单。",
                           tags: ["探店", "火锅", "预算控局"], avail: "今晚可约", active: "刚刚活跃", looking: "可接探店陪吃"),
            serviceType: .offline, specialty: "火锅探店陪吃",
            hourlyPrice: 128, rating: 4.9, orderCount: 88, isAvailable: true,
            responseTime: "通常 15 分钟内",
            scheduleSlots: ["今晚 18:30", "周六 12:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "木子", rating: 5, comment: "控辣控预算都很稳。", dateText: "4 天前")
            ],
            relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "南栀", gender: .female, age: 27, h: 168, w: 52, km: 1.8,
                           seeds: [750, 751, 760], city: "成都 · 青羊",
                           bio: "宽窄 / 少城慢逛陪玩，含点位讲解与拍照指导。",
                           tags: ["漫步", "展览", "拍照点"], avail: "档期已满", active: "昨天活跃", looking: "本周档期已满"),
            serviceType: .offline, specialty: "少城慢逛陪逛",
            hourlyPrice: 138, rating: 4.9, orderCount: 61, isAvailable: false,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["下周六待开放"],
            reviews: [
                BuddyReview(id: UUID(), author: "青禾", rating: 5, comment: "路线很会拍，体验完整。", dateText: "5 天前")
            ],
            relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "青禾", gender: .female, age: 25, h: 161, w: 48, km: 8.2,
                           seeds: [770, 771, 780], city: "成都 · 龙泉驿",
                           bio: "龙泉山轻徒步向导，含集合指引与轻松讲解。门票与交通自理。",
                           tags: ["徒步", "看花", "植物科普"], avail: "本周日可约", active: "今天活跃", looking: "可接轻徒步向导"),
            serviceType: .offline, specialty: "轻徒步线下向导",
            hourlyPrice: 148, rating: 4.7, orderCount: 39, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["周日 09:00", "下周日 09:00"],
            reviews: [
                BuddyReview(id: UUID(), author: "匿名用户", rating: 4, comment: "节奏轻松，适合拍照。", dateText: "1 周前")
            ],
            relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "老白", gender: .male, age: 30, h: 176, w: 70, km: 4.6,
                           seeds: [790, 791, 800], city: "成都 · 成华",
                           bio: "夜跑陪跑与拉伸指导，可按配速分组。",
                           tags: ["跑步", "拉伸", "陪跑"], avail: "今晚可约", active: "在线", looking: "可接夜跑陪跑"),
            serviceType: .activity, specialty: "夜跑陪跑",
            hourlyPrice: 108, rating: 4.8, orderCount: 54, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["今晚 19:30", "周五 19:30"],
            reviews: [
                BuddyReview(id: UUID(), author: "叙叙", rating: 5, comment: "配速稳，拉伸到位。", dateText: "3 天前")
            ],
            relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "江晚", gender: .female, age: 23, h: 158, w: 45, km: 3.1,
                           seeds: [810, 811, 820], city: "成都 · 武侯",
                           bio: "市集 / 玉林拍照陪拍，出图快，可按风格沟通。",
                           tags: ["摄影", "市集", "陪拍"], avail: "周末可约", active: "今天活跃", looking: "可接陪拍"),
            serviceType: .offline, specialty: "市集陪拍",
            hourlyPrice: 148, rating: 4.9, orderCount: 41, isAvailable: true,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["周六下午", "周日上午"],
            reviews: [
                BuddyReview(id: UUID(), author: "小满", rating: 5, comment: "出片自然，沟通顺。", dateText: "5 天前")
            ],
            relatedActivityTitles: []
        ),
        // MARK: 上海陪玩扩充
        PaidCompanion(
            profile: buddy(nick: "北辰", gender: .male, age: 28, h: 179, w: 71, km: 1.1,
                           seeds: [1401, 1402, 1403], city: "上海 · 黄浦",
                           bio: "滨江骑行陪玩，含安全提醒与补给建议。",
                           tags: ["骑行", "新手友好", "路线规划"], avail: "今日可约", active: "在线", looking: "可接夜骑陪玩"),
            serviceType: .activity, specialty: "城市骑行陪玩",
            hourlyPrice: 118, rating: 4.8, orderCount: 58, isAvailable: true,
            responseTime: "通常 15 分钟内",
            scheduleSlots: ["今日 20:00", "周六 09:00"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "柚子", gender: .female, age: 24, h: 161, w: 47, km: 1.9,
                           seeds: [1411, 1412, 1413], city: "上海 · 静安",
                           bio: "羽毛球陪练，可轻度纠正动作，场地费另计。",
                           tags: ["羽毛球", "陪练", "纠正动作"], avail: "今晚可约", active: "在线", looking: "可接羽毛球陪练"),
            serviceType: .activity, specialty: "羽毛球陪练",
            hourlyPrice: 158, rating: 4.9, orderCount: 72, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["今晚 20:00", "周三 19:30"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "老陈", gender: .male, age: 33, h: 174, w: 69, km: 3.2,
                           seeds: [1421, 1422, 1423], city: "上海 · 徐汇",
                           bio: "按预算定制探店路线，陪吃陪逛。",
                           tags: ["探店", "预算控局", "夜市"], avail: "今晚可约", active: "刚刚活跃", looking: "可接探店陪吃"),
            serviceType: .offline, specialty: "美食探店陪吃",
            hourlyPrice: 128, rating: 4.7, orderCount: 91, isAvailable: true,
            responseTime: "通常 15 分钟内",
            scheduleSlots: ["今晚 18:30", "周六 12:00"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "安安", gender: .female, age: 22, h: 159, w: 45, km: 4.5,
                           seeds: [1431, 1432, 1433], city: "上海 · 浦东",
                           bio: "夜跑陪跑与跑后拉伸，可按配速分组。",
                           tags: ["跑步", "拉伸", "陪跑"], avail: "今晚可约", active: "在线", looking: "可接夜跑陪跑"),
            serviceType: .activity, specialty: "夜跑陪跑",
            hourlyPrice: 108, rating: 4.8, orderCount: 44, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["今晚 19:30"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "阿梨", gender: .female, age: 29, h: 167, w: 53, km: 2.4,
                           seeds: [1441, 1442, 1443], city: "上海 · 黄浦",
                           bio: "逛街探店陪逛，不劝买，适合不想独自逛的周末。",
                           tags: ["逛街", "探店", "拍照点"], avail: "周末可约", active: "今天活跃", looking: "可接陪逛"),
            serviceType: .offline, specialty: "逛街探店陪逛",
            hourlyPrice: 138, rating: 4.9, orderCount: 36, isAvailable: true,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["周六下午", "周日 14:00"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "言午", gender: .male, age: 27, h: 181, w: 75, km: 6.0,
                           seeds: [1451, 1452, 1453], city: "上海 · 浦东",
                           bio: "网球 / 羽毛球陪练，入门友好。",
                           tags: ["网球", "羽毛球", "陪练"], avail: "明日可约", active: "今天活跃", looking: "可接球类陪练"),
            serviceType: .activity, specialty: "网球羽毛球陪练",
            hourlyPrice: 168, rating: 4.8, orderCount: 53, isAvailable: true,
            responseTime: "通常 30 分钟内",
            scheduleSlots: ["明日 19:00", "周四 19:00"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "小满满", gender: .female, age: 25, h: 163, w: 48, km: 3.8,
                           seeds: [1461, 1462, 1463], city: "上海 · 长宁",
                           bio: "市集陪拍，出图快，可沟通风格。",
                           tags: ["摄影", "市集", "陪拍"], avail: "周末可约", active: "今天活跃", looking: "可接陪拍"),
            serviceType: .offline, specialty: "市集陪拍",
            hourlyPrice: 148, rating: 4.9, orderCount: 29, isAvailable: true,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["周六下午", "周日上午"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "苏苏", gender: .female, age: 27, h: 165, w: 50, km: 1.3,
                           seeds: [1471, 1472, 1473], city: "上海 · 静安",
                           bio: "展览 / 书店线下陪逛，按兴趣规划路线。",
                           tags: ["展览", "书店", "咖啡"], avail: "档期已满", active: "昨天活跃", looking: "本周档期已满"),
            serviceType: .offline, specialty: "展览书店陪逛",
            hourlyPrice: 142, rating: 4.8, orderCount: 40, isAvailable: false,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["下周六待开放"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "青杉", gender: .male, age: 32, h: 177, w: 73, km: 9.8,
                           seeds: [1481, 1482, 1483], city: "上海 · 松江",
                           bio: "轻徒步向导，含集合指引；门票交通自理。",
                           tags: ["徒步", "野餐", "植物科普"], avail: "本周日可约", active: "今天活跃", looking: "可接轻徒步向导"),
            serviceType: .offline, specialty: "轻徒步向导",
            hourlyPrice: 152, rating: 4.7, orderCount: 33, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["周日 09:00"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "阿白", gender: .male, age: 26, h: 173, w: 66, km: 4.1,
                           seeds: [1491, 1492, 1493], city: "上海 · 黄浦",
                           bio: "夜骑续摊陪玩，可按配速定制。",
                           tags: ["骑行", "夜骑", "新手友好"], avail: "周五可约", active: "在线", looking: "可接夜骑陪玩"),
            serviceType: .activity, specialty: "夜骑陪玩",
            hourlyPrice: 122, rating: 4.8, orderCount: 47, isAvailable: true,
            responseTime: "通常 10 分钟内",
            scheduleSlots: ["周五 21:00", "周六 20:00"],
            reviews: [], relatedActivityTitles: []
        ),
        // MARK: 成都陪玩扩充
        PaidCompanion(
            profile: buddy(nick: "豆豆", gender: .female, age: 24, h: 160, w: 46, km: 2.2,
                           seeds: [1501, 1502, 1503], city: "成都 · 武侯",
                           bio: "火锅 / 串串陪吃，控辣控预算。",
                           tags: ["火锅", "探店", "预算控局"], avail: "今晚可约", active: "刚刚活跃", looking: "可接探店陪吃"),
            serviceType: .offline, specialty: "火锅陪吃",
            hourlyPrice: 118, rating: 4.9, orderCount: 55, isAvailable: true,
            responseTime: "通常 15 分钟内",
            scheduleSlots: ["今晚 18:30"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "阿泽", gender: .male, age: 29, h: 178, w: 72, km: 1.5,
                           seeds: [1511, 1512, 1513], city: "成都 · 锦江",
                           bio: "东湖夜骑陪玩，含路线讲解。",
                           tags: ["骑行", "路线规划", "新手友好"], avail: "今日可约", active: "在线", looking: "可接夜骑陪玩"),
            serviceType: .activity, specialty: "夜骑陪玩",
            hourlyPrice: 112, rating: 4.8, orderCount: 62, isAvailable: true,
            responseTime: "通常 10 分钟内",
            scheduleSlots: ["今日 20:00"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "禾禾", gender: .female, age: 26, h: 165, w: 51, km: 3.0,
                           seeds: [1521, 1522, 1523], city: "成都 · 高新区",
                           bio: "羽毛球陪练，工作日晚饭后灵活。",
                           tags: ["羽毛球", "陪练", "拉伸"], avail: "工作日可约", active: "今天活跃", looking: "可接羽毛球陪练"),
            serviceType: .activity, specialty: "羽毛球陪练",
            hourlyPrice: 148, rating: 4.8, orderCount: 49, isAvailable: true,
            responseTime: "通常 30 分钟内",
            scheduleSlots: ["周二 19:30", "周四 19:30"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "清清", gender: .female, age: 28, h: 168, w: 52, km: 2.6,
                           seeds: [1531, 1532, 1533], city: "成都 · 青羊",
                           bio: "少城慢逛陪逛，含点位与拍照建议。",
                           tags: ["漫步", "展览", "拍照点"], avail: "周末可约", active: "今天活跃", looking: "可接陪逛"),
            serviceType: .offline, specialty: "少城慢逛陪逛",
            hourlyPrice: 132, rating: 4.9, orderCount: 38, isAvailable: true,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["周六下午"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "石头", gender: .male, age: 31, h: 175, w: 74, km: 7.5,
                           seeds: [1541, 1542, 1543], city: "成都 · 龙泉驿",
                           bio: "龙泉轻徒步向导，节奏慢适合拍照。",
                           tags: ["徒步", "看花", "植物科普"], avail: "本周日可约", active: "昨天活跃", looking: "可接轻徒步向导"),
            serviceType: .offline, specialty: "轻徒步向导",
            hourlyPrice: 138, rating: 4.7, orderCount: 27, isAvailable: true,
            responseTime: "通常 20 分钟内",
            scheduleSlots: ["周日 09:00"],
            reviews: [], relatedActivityTitles: []
        ),
        PaidCompanion(
            profile: buddy(nick: "橙子", gender: .female, age: 23, h: 158, w: 44, km: 4.0,
                           seeds: [1551, 1552, 1553], city: "成都 · 金牛",
                           bio: "市集陪拍与轻松出片，可沟通风格。",
                           tags: ["摄影", "市集", "陪拍"], avail: "周末可约", active: "今天活跃", looking: "可接陪拍"),
            serviceType: .offline, specialty: "市集陪拍",
            hourlyPrice: 128, rating: 4.8, orderCount: 22, isAvailable: true,
            responseTime: "通常 1 小时内",
            scheduleSlots: ["周六下午"],
            reviews: [], relatedActivityTitles: []
        )
    ]

    // MARK: - Authors

    static let authorProfiles: [String: AuthorDirectoryProfile] = [
        "坐标系小队": .init(name: "坐标系小队", city: "上海", bio: "官方内容与周末精选活动整理。帮你筛出好玩又不卷的同城局。", tags: ["精选", "周末", "上海"], hostedCount: 48, joinedCount: 120, roleLabel: "官方账号"),
        "阿凯": .init(name: "阿凯", city: "上海 · 黄浦", bio: "夜骑爱好者，喜欢轻松局和城市探索。", tags: ["骑行", "摄影", "咖啡"], hostedCount: 12, joinedCount: 36, roleLabel: "活跃发起人"),
        "Mia": .init(name: "Mia", city: "上海 · 徐汇", bio: "常出没于小展和独立书店，也喜欢安静的咖啡聊天。", tags: ["展览", "咖啡", "市集"], hostedCount: 9, joinedCount: 28, roleLabel: "社区作者"),
        "小周": .init(name: "小周", city: "上海 · 静安", bio: "吃货但控预算，欢迎一起做区域美食攻略。", tags: ["美食", "探店"], hostedCount: 7, joinedCount: 22, roleLabel: "社区作者"),
        "林夏": .init(name: "林夏", city: "上海 · 徐汇", bio: "周末爱逛市集和手作摊，也愿意当新人向导。", tags: ["市集", "摄影"], hostedCount: 5, joinedCount: 31, roleLabel: "社区作者"),
        "阿禾": .init(name: "阿禾", city: "上海 · 松江", bio: "偏好不卷的户外，重点是呼吸新鲜空气和拍树。", tags: ["徒步", "植物"], hostedCount: 11, joinedCount: 19, roleLabel: "活跃发起人"),
        "Leo": .init(name: "Leo", city: "上海 · 静安", bio: "羽毛球 / 网球都玩，喜欢固定局。", tags: ["羽毛球", "网球"], hostedCount: 8, joinedCount: 25, roleLabel: "运动搭子"),
        "Yuna": .init(name: "Yuna", city: "上海 · 浦东", bio: "寻找长期固定运动搭子，也做轻度陪练。", tags: ["羽毛球", "拉伸"], hostedCount: 6, joinedCount: 40, roleLabel: "运动搭子"),
        "Noon": .init(name: "Noon", city: "上海 · 普陀", bio: "夜跑与城市散步组织者，配速友好。", tags: ["跑步", "建筑"], hostedCount: 10, joinedCount: 27, roleLabel: "活跃发起人"),
        "Coco": .init(name: "Coco", city: "上海 · 黄浦", bio: "喜欢市集淘物和胶片感拍照。", tags: ["摄影", "市集"], hostedCount: 3, joinedCount: 18, roleLabel: "社区作者"),
        "阿哲": .init(name: "阿哲", city: "上海 · 浦东", bio: "晨练拉伸与轻力量，适合上班族早晨空档。", tags: ["拉伸", "跑步"], hostedCount: 4, joinedCount: 15, roleLabel: "社区作者"),
        // 成都
        "阿川": .init(name: "阿川", city: "成都 · 锦江", bio: "东湖夜骑常客，也接城市骑行陪玩。", tags: ["骑行", "摄影", "美食"], hostedCount: 9, joinedCount: 28, roleLabel: "活跃发起人"),
        "小满": .init(name: "小满", city: "成都 · 武侯", bio: "火锅拼桌与探店，控辣控预算。", tags: ["美食", "咖啡", "市集"], hostedCount: 6, joinedCount: 24, roleLabel: "社区作者"),
        "叙叙": .init(name: "叙叙", city: "成都 · 高新区", bio: "羽毛球固搭 / 陪练，工作日晚饭后灵活。", tags: ["羽毛球", "拉伸"], hostedCount: 5, joinedCount: 33, roleLabel: "运动搭子"),
        "南栀": .init(name: "南栀", city: "成都 · 青羊", bio: "宽窄慢逛与咖啡馆常客。", tags: ["展览", "咖啡", "摄影"], hostedCount: 4, joinedCount: 19, roleLabel: "社区作者"),
        "老白": .init(name: "老白", city: "成都 · 成华", bio: "夜跑配速友好，跑后串串收尾。", tags: ["跑步", "美食"], hostedCount: 7, joinedCount: 21, roleLabel: "活跃发起人"),
        "青禾": .init(name: "青禾", city: "成都 · 龙泉驿", bio: "龙泉山轻徒步与看花局。", tags: ["徒步", "摄影"], hostedCount: 8, joinedCount: 17, roleLabel: "活跃发起人"),
        "木子": .init(name: "木子", city: "成都 · 金牛", bio: "桌游开黑与茶馆摆龙门阵。", tags: ["桌游", "咖啡"], hostedCount: 3, joinedCount: 14, roleLabel: "社区作者"),
        "江晚": .init(name: "江晚", city: "成都 · 武侯", bio: "市集淘物与胶片感拍照。", tags: ["摄影", "市集"], hostedCount: 2, joinedCount: 12, roleLabel: "社区作者")
    ]

    static func author(named name: String) -> AuthorDirectoryProfile {
        authorProfiles[name] ?? AuthorDirectoryProfile(
            name: name,
            city: "上海",
            bio: "还在完善个人主页，先聊聊近期想去的局吧。",
            tags: ["同城", "交友"],
            hostedCount: 0,
            joinedCount: 0,
            roleLabel: "坐标系用户"
        )
    }

    // MARK: - Posts

    static let posts: [CommunityPost] = [
        CommunityPost(
            id: postID(1), author: "坐标系小队", title: "本周值得去的 5 个周末局",
            body: "从滨江市集到夜骑，再到咖啡漫谈，帮你快速筛出这周末好玩又不卷的活动。收藏后按兴趣报名就行。",
            tags: ["周末", "精选", "上海"], likeCount: 1280, commentCount: 46, repostCount: 210, shareCount: 188,
            postedAt: hours(-5), isPinned: true, photoSeeds: [201, 202, 203], photoHue: 0.58,
            relatedActivityTitle: "外滩夜骑轻态局", relatedActivityID: uid(2),
            comments: {
                let rootA = UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!
                let rootB = UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!
                let rootC = UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!
                return [
                    CommunityComment(
                        id: rootA, author: "阿凯", text: "夜骑那条路线收藏了，周五见。",
                        postedAt: hours(-3), likeCount: 24, region: "上海"
                    ),
                    CommunityComment(
                        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000011")!,
                        author: "Mia", text: "我也报名了，外滩集合吧。",
                        postedAt: hours(-2), parentID: rootA, replyToAuthor: "阿凯",
                        likeCount: 6, region: "上海"
                    ),
                    CommunityComment(
                        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000012")!,
                        author: "小周", text: "求个拼车位～",
                        postedAt: hours(-2), parentID: rootA, replyToAuthor: "阿凯",
                        likeCount: 3, region: "江苏"
                    ),
                    CommunityComment(
                        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000013")!,
                        author: "林夏", text: "带反光条，滨江风大。",
                        postedAt: hours(-1), parentID: rootA, replyToAuthor: "Mia",
                        likeCount: 8, region: "上海"
                    ),
                    CommunityComment(
                        id: rootB, author: "Mia", text: "市集时段写得很清楚，赞。",
                        postedAt: hours(-2), likeCount: 15, region: "浙江"
                    ),
                    CommunityComment(
                        id: rootC, author: "小周", text: "咖啡局也想去，有人拼车吗？",
                        postedAt: hours(-1), likeCount: 9, region: "上海"
                    ),
                    CommunityComment(
                        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000021")!,
                        author: "阿禾", text: "我可以顺路带两位。",
                        postedAt: hours(-1), parentID: rootC, replyToAuthor: "小周",
                        likeCount: 4, region: "上海"
                    )
                ]
            }(),
            likerNames: ["阿凯", "Mia", "小周", "林夏", "阿禾"]
        ),
        CommunityPost(
            id: postID(2), author: "阿凯", title: "第一次组夜骑，避坑分享",
            body: "路线别太长、提前确认单车状态、终点准备水和简单补给。人不多反而更轻松，适合新手局。",
            tags: ["夜骑", "经验", "新手友好"], likeCount: 64, commentCount: 2, repostCount: 42, shareCount: 88,
            postedAt: hours(-18), isPinned: false, photoSeeds: [301, 302], photoHue: 0.62,
            relatedActivityTitle: "外滩夜骑轻态局", relatedActivityID: uid(2),
            comments: [
                CommunityComment(id: UUID(), author: "林夏", text: "补给这点太重要了，上次渴坏。", postedAt: hours(-10)),
                CommunityComment(id: UUID(), author: "阿禾", text: "武康路那条也适用，马克。", postedAt: hours(-8))
            ]
        ),
        CommunityPost(
            id: postID(3), author: "小周", title: "武康路三家好吃不贵",
            body: "Brunch、提拉米苏、关东煮夜点。周末局结束后可以接着串，人均可控。",
            tags: ["探店", "美食", "武康路"], likeCount: 97, commentCount: 2, repostCount: 61, shareCount: 120,
            postedAt: hours(-46), isPinned: false, photoSeeds: [501, 502, 503], photoHue: 0.05,
            relatedActivityTitle: "武康路美食散打", relatedActivityID: uid(6),
            comments: [
                CommunityComment(id: UUID(), author: "Mia", text: "提拉米苏那家同意，周末排队短。", postedAt: hours(-40)),
                CommunityComment(id: UUID(), author: "坐标系小队", text: "已加进本周精选里啦。", postedAt: hours(-36))
            ]
        ),
        CommunityPost(
            id: postID(4), author: "林夏", title: "辰山轻徒步拍照点位",
            body: "入口左手第二条支路、湖心栈道拐弯处、终点草坪。周末人不多，光线也友好。",
            tags: ["徒步", "拍照", "周末"], likeCount: 53, commentCount: 2, repostCount: 28, shareCount: 55,
            postedAt: hours(-12), isPinned: false, photoSeeds: [601, 602], photoHue: 0.33,
            relatedActivityTitle: "辰山植物园轻徒步", relatedActivityID: uid(5),
            comments: [
                CommunityComment(id: UUID(), author: "阿禾", text: "栈道那张太好看了。", postedAt: hours(-8)),
                CommunityComment(id: UUID(), author: "Mia", text: "下周按这个路线走。", postedAt: hours(-6))
            ]
        ),
        CommunityPost(
            id: postID(5), author: "阿禾", title: "市集半日逛法",
            body: "先手作区再刊物摊，午饭避开主通道。傍晚灯光起来后适合收尾拍照。",
            tags: ["市集", "手作", "徐汇"], likeCount: 41, commentCount: 1, repostCount: 19, shareCount: 36,
            postedAt: hours(-28), isPinned: false, photoSeeds: [401, 402], photoHue: 0.08,
            relatedActivityTitle: "徐汇滨江市集漫逛", relatedActivityID: uid(4),
            comments: [CommunityComment(id: UUID(), author: "小周", text: "刊物摊收藏了，谢分享。", postedAt: hours(-20))]
        ),
        CommunityPost(
            id: postID(6), author: "Noon", title: "苏州河夜跑补给清单",
            body: "半马不是目标，5K 轻松完赛更重要。电解质、头灯、反光条，三件套就够。",
            tags: ["夜跑", "补给"], likeCount: 72, commentCount: 3, repostCount: 15, shareCount: 40,
            postedAt: hours(-8), isPinned: false, photoSeeds: [701, 702], photoHue: 0.48,
            relatedActivityTitle: "苏州河夜跑 5K", relatedActivityID: uid(8),
            comments: [
                CommunityComment(id: UUID(), author: "Leo", text: "反光条这点太关键了。", postedAt: hours(-6)),
                CommunityComment(id: UUID(), author: "阿哲", text: "明早拉伸局也适用。", postedAt: hours(-5)),
                CommunityComment(id: UUID(), author: "林屿", text: "今晚跟着你们跑。", postedAt: hours(-4))
            ]
        ),
        CommunityPost(
            id: postID(7), author: "Mia", title: "安福路书店咖啡组合",
            body: "先翻书再咖啡，别反过来——咖啡因上来就坐不住了。两家店步行 8 分钟。",
            tags: ["书店", "咖啡"], likeCount: 58, commentCount: 2, repostCount: 22, shareCount: 33,
            postedAt: hours(-22), isPinned: false, photoSeeds: [711, 712, 713], photoHue: 0.9,
            relatedActivityTitle: "安福路独立书店半日", relatedActivityID: uid(9),
            comments: [
                CommunityComment(id: UUID(), author: "林夏", text: "第二家窗边位绝了。", postedAt: hours(-18)),
                CommunityComment(id: UUID(), author: "Coco", text: "想一起去拍照。", postedAt: hours(-16))
            ]
        ),
        CommunityPost(
            id: postID(8), author: "Yuna", title: "羽毛球约场避坑",
            body: "工作日晚高峰要提前一天锁场。新人局把水平写清楚，比临时加赛友好得多。",
            tags: ["羽毛球", "约场"], likeCount: 45, commentCount: 2, repostCount: 11, shareCount: 27,
            postedAt: hours(-33), isPinned: false, photoSeeds: [721], photoHue: 0.76,
            relatedActivityTitle: "羽毛球混双打野", relatedActivityID: uid(7),
            comments: [
                CommunityComment(id: UUID(), author: "Leo", text: "同意，水平备注超重要。", postedAt: hours(-30)),
                CommunityComment(id: UUID(), author: "阿凯", text: "源深那家停车也方便。", postedAt: hours(-28))
            ]
        ),
        CommunityPost(
            id: postID(9), author: "Coco", title: "外滩夜骑拍照姿势",
            body: "骑行中别硬拍。到灯带密的桥段再停，侧逆光最出片，安全第一。",
            tags: ["摄影", "夜骑"], likeCount: 88, commentCount: 2, repostCount: 34, shareCount: 51,
            postedAt: hours(-15), isPinned: false, photoSeeds: [731, 732], photoHue: 0.66,
            relatedActivityTitle: "外滩夜骑轻态局", relatedActivityID: uid(2),
            comments: [
                CommunityComment(id: UUID(), author: "阿凯", text: "桥段那张我收了。", postedAt: hours(-12)),
                CommunityComment(id: UUID(), author: "林夏", text: "下次一起试侧逆光。", postedAt: hours(-11))
            ]
        ),
        CommunityPost(
            id: postID(10), author: "阿哲", title: "晨间拉伸 10 分钟版",
            body: "颈肩、髋、小腿。滨江风大时先热身再拉伸，别一到就压腿。",
            tags: ["拉伸", "晨练"], likeCount: 36, commentCount: 1, repostCount: 9, shareCount: 18,
            postedAt: hours(-40), isPinned: false, photoSeeds: [741], photoHue: 0.4,
            relatedActivityTitle: "陆家嘴晨间拉伸局", relatedActivityID: uid(12),
            comments: [CommunityComment(id: UUID(), author: "Yuna", text: "已转给晨练群。", postedAt: hours(-35))]
        ),
        CommunityPost(
            id: postID(11), author: "Leo", title: "网球入门对打怎么开局",
            body: "先喂球 15 分钟再对打，比一上来计分友好。球拍借得到，别因为装备缺席。",
            tags: ["网球", "入门"], likeCount: 29, commentCount: 1, repostCount: 7, shareCount: 14,
            postedAt: hours(-55), isPinned: false, photoSeeds: [751, 752], photoHue: 0.5,
            relatedActivityTitle: "网球入门对打", relatedActivityID: uid(15),
            comments: [CommunityComment(id: UUID(), author: "Yuna", text: "周四我可以带一把备用拍。", postedAt: hours(-50))]
        ),
        CommunityPost(
            id: postID(12), author: "坐标系小队", title: "满员活动怎么候补？",
            body: "详情页点「加入候补」。有人退出或名额释放时，会收到本地通知，再打开活动详情一键报名。",
            tags: ["指南", "候补"], likeCount: 112, commentCount: 4, repostCount: 40, shareCount: 66,
            postedAt: hours(-70), isPinned: false, photoSeeds: [761], photoHue: 0.55,
            comments: [
                CommunityComment(id: UUID(), author: "小周", text: "拉面局就靠这个进的。", postedAt: hours(-65)),
                CommunityComment(id: UUID(), author: "Mia", text: "比一直刷新列表省心。", postedAt: hours(-60))
            ]
        )
    ]

    // MARK: - Messages

    static let conversations: [ChatConversation] = [
        ChatConversation(
            id: chatID(1), title: "外滩滨江夜骑", subtitle: "群聊",
            lastMessage: "门口有个白色标识，不好找可以问我",
            updatedAt: .now.addingTimeInterval(-60 * 10), unreadCount: 3, kind: .activity,
            eventAt: day(0, hour: 19, minute: 30), relatedActivityID: uid(2),
            ownerName: "阿凯",
            memberNames: ["阿凯", "林屿", "林夏", "Coco"]
        ),
        ChatConversation(
            id: chatID(2), title: "Mia", subtitle: "好友",
            lastMessage: "思南那家窗边位我帮你留意一下",
            updatedAt: hours(-1.8), unreadCount: 1, kind: .direct,
            peerIsActive: true
        ),
        ChatConversation(
            id: chatID(3), title: "烧烤撸串夜局", subtitle: "群聊",
            lastMessage: "阿禾：串量够不够啊，我再带点蔬菜",
            updatedAt: hours(-6), unreadCount: 0, kind: .activity,
            eventAt: day(2, hour: 9), relatedActivityID: uid(5),
            ownerName: "串串阿木",
            memberNames: ["串串阿木", "林屿", "阿禾", "林夏"],
            announcement: "今晚 19:30 集合，每人自备饮料。"
        ),
        ChatConversation(
            id: chatID(4), title: "小周", subtitle: "好友",
            lastMessage: "人均控在 120 左右，预算友好",
            updatedAt: hours(-25), unreadCount: 0, kind: .direct
        ),
        ChatConversation(
            id: chatID(5), title: "坐标系周末通告", subtitle: "通知",
            lastMessage: "本周精选活动已更新，去活动页看看",
            updatedAt: hours(-40), unreadCount: 0, kind: .notice
        ),
        ChatConversation(
            id: chatID(6), title: "羽毛球混双打野", subtitle: "群聊",
            lastMessage: "Leo：场地在 3 号馆，我提前 10 分钟到",
            updatedAt: hours(-1.5), unreadCount: 2, kind: .activity,
            eventAt: hours(28), relatedActivityID: uid(7),
            ownerName: "阿凯"
        ),
        ChatConversation(
            id: chatID(7), title: "Yuna", subtitle: "好友",
            lastMessage: "周四晚上你方便吗？",
            updatedAt: hours(-4), unreadCount: 0, kind: .direct
        ),
        ChatConversation(
            id: chatID(8), title: "苏州河夜跑 5K", subtitle: "群聊",
            lastMessage: "Noon：终点有拉伸，别直接走哦",
            updatedAt: hours(-0.5), unreadCount: 1, kind: .activity,
            eventAt: day(0, hour: 19, minute: 30), relatedActivityID: uid(8),
            ownerName: "Noon"
        ),
        ChatConversation(
            id: chatID(9), title: "林夏", subtitle: "好友",
            lastMessage: "太好了，到时候群里同步集合点。",
            updatedAt: hours(-8), unreadCount: 0, kind: .direct
        ),
        ChatConversation(
            id: chatID(10), title: "小满", subtitle: "好友",
            lastMessage: "嗨，看了你主页想认识一下～",
            updatedAt: hours(-0.2), unreadCount: 1, kind: .direct,
            isMessageRequest: true
        )
    ]

    static let friendRequests: [FriendRequest] = [
        FriendRequest(
            id: uid(801),
            fromName: "阿哲",
            message: "你好，看到你也常跑步，想认识一下～",
            createdAt: hours(-0.2),
            status: .pending
        ),
        FriendRequest(
            id: uid(802),
            fromName: "Coco",
            message: "夜骑局认识的，加个好友方便组队",
            createdAt: hours(-5),
            status: .pending
        )
    ]

    static func messages(for conversationID: UUID) -> [ChatMessage] {
        switch conversationID {
        case chatID(1):
            [
                ChatMessage.systemTip("阿凯创建了群聊", at: hours(-2)),
                ChatMessage.systemTip("林屿加入了群聊", at: hours(-1.9)),
                ChatMessage(id: UUID(), sender: "阿凯", text: "各位今晚还按时吗？", sentAt: hours(-1), isMe: false),
                ChatMessage(id: UUID(), sender: "我", text: "我七点半能到外滩。", sentAt: .now.addingTimeInterval(-3500), isMe: true, deliveryStatus: .read),
                ChatMessage(id: UUID(), sender: "林夏", text: "我也差不多，顺便确认下路线。", sentAt: .now.addingTimeInterval(-3400), isMe: false),
                ChatMessage(
                    id: UUID(), sender: "Coco", text: "位置", sentAt: .now.addingTimeInterval(-2100), isMe: false,
                    messageKind: .location, locationName: "外滩格林邮轮码头", latitude: 31.24, longitude: 121.49
                ),
                ChatMessage(id: UUID(), sender: "Coco", text: "我带了头灯，需要的可以借。", sentAt: .now.addingTimeInterval(-2000), isMe: false),
                ChatMessage(
                    id: UUID(), sender: "我", text: "👍", sentAt: .now.addingTimeInterval(-1800), isMe: true,
                    messageKind: .sticker, deliveryStatus: .delivered
                ),
                ChatMessage(id: UUID(), sender: "阿凯", text: "集合点改到格林邮轮码头入口", sentAt: .now.addingTimeInterval(-60 * 12), isMe: false),
                ChatMessage(id: UUID(), sender: "阿凯", text: "门口有个白色标识，不好找可以问我", sentAt: .now.addingTimeInterval(-60 * 10), isMe: false)
            ]
        case chatID(2):
            [
                ChatMessage(id: UUID(), sender: "Mia", text: "周末还去咖啡漫谈吗？", sentAt: hours(-3), isMe: false),
                ChatMessage(id: UUID(), sender: "我", text: "去呀，我大概两点到。", sentAt: hours(-2.5), isMe: true),
                ChatMessage(id: UUID(), sender: "Mia", text: "那我们咖啡局见～", sentAt: hours(-2), isMe: false),
                ChatMessage(id: UUID(), sender: "Mia", text: "思南那家窗边位我帮你留意一下", sentAt: hours(-1.8), isMe: false)
            ]
        case chatID(3):
            [
                ChatMessage.systemTip("串串阿木创建了群聊", at: hours(-9)),
                ChatMessage.systemTip("林屿加入了群聊", at: hours(-8.5)),
                ChatMessage(id: UUID(), sender: "阿禾", text: "今晚烧烤还按原计划吗？", sentAt: hours(-8), isMe: false),
                ChatMessage(id: UUID(), sender: "我", text: "去呀，我带几瓶饮料。", sentAt: hours(-7), isMe: true),
                ChatMessage(id: UUID(), sender: "林夏", text: "我可以带铝箔纸和湿巾。", sentAt: hours(-6.5), isMe: false),
                ChatMessage(id: UUID(), sender: "阿禾", text: "串量够不够啊，我再带点蔬菜", sentAt: hours(-6), isMe: false)
            ]
        case chatID(4):
            [
                ChatMessage(id: UUID(), sender: "小周", text: "你看过那家新开的面馆吗？", sentAt: hours(-30), isMe: false),
                ChatMessage(id: UUID(), sender: "我", text: "还没有，周末一起？", sentAt: hours(-28), isMe: true),
                ChatMessage(id: UUID(), sender: "小周", text: "周末美食局还差两个人", sentAt: hours(-26), isMe: false),
                ChatMessage(id: UUID(), sender: "小周", text: "人均控在 120 左右，预算友好", sentAt: hours(-25), isMe: false)
            ]
        case chatID(5):
            [
                ChatMessage(id: UUID(), sender: "坐标系", text: "你好，这是坐标系官方通知。", sentAt: hours(-42), isMe: false),
                ChatMessage(id: UUID(), sender: "坐标系", text: "本周精选活动已更新，去活动页看看", sentAt: hours(-40), isMe: false),
                ChatMessage(id: UUID(), sender: "坐标系", text: "满员活动可加入候补，有名额会提醒你。", sentAt: hours(-39), isMe: false)
            ]
        case chatID(6):
            [
                ChatMessage.systemTip("阿凯创建了群聊", at: hours(-4)),
                ChatMessage.systemTip("林屿加入了群聊", at: hours(-3.5)),
                ChatMessage(id: UUID(), sender: "Leo", text: "今晚混双还差一个人，有人带朋友吗？", sentAt: hours(-3), isMe: false),
                ChatMessage(id: UUID(), sender: "Yuna", text: "我可以问问同事。", sentAt: hours(-2.5), isMe: false),
                ChatMessage(id: UUID(), sender: "我", text: "我按时到，球拍自备。", sentAt: hours(-2), isMe: true),
                ChatMessage(id: UUID(), sender: "Leo", text: "场地在 3 号馆，我提前 10 分钟到", sentAt: hours(-1.5), isMe: false)
            ]
        case chatID(7):
            [
                ChatMessage(id: UUID(), sender: "Yuna", text: "看到你也常打羽毛球～", sentAt: hours(-6), isMe: false),
                ChatMessage(id: UUID(), sender: "我", text: "是呀，最近在找固定搭子。", sentAt: hours(-5), isMe: true),
                ChatMessage(id: UUID(), sender: "Yuna", text: "周四晚上你方便吗？", sentAt: hours(-4), isMe: false)
            ]
        case chatID(8):
            [
                ChatMessage.systemTip("Noon创建了群聊", at: hours(-3)),
                ChatMessage.systemTip("林屿加入了群聊", at: hours(-2.5)),
                ChatMessage(id: UUID(), sender: "Noon", text: "今晚配速大概 6'30，跟得上就行。", sentAt: hours(-2), isMe: false),
                ChatMessage(id: UUID(), sender: "阿哲", text: "我带了拉伸带。", sentAt: hours(-1), isMe: false),
                ChatMessage(id: UUID(), sender: "Noon", text: "终点有拉伸，别直接走哦", sentAt: hours(-0.5), isMe: false)
            ]
        case chatID(9):
            [
                ChatMessage(id: UUID(), sender: "林夏", text: "世纪公园野餐你要来吗？", sentAt: hours(-9), isMe: false),
                ChatMessage(id: UUID(), sender: "我", text: "想去！我可以带相机。", sentAt: hours(-8.5), isMe: true),
                ChatMessage(id: UUID(), sender: "林夏", text: "太好了，到时候群里同步集合点。", sentAt: hours(-8), isMe: false)
            ]
        case chatID(10):
            [
                ChatMessage(
                    id: UUID(), sender: "小满",
                    text: "嗨，看了你主页想认识一下～",
                    sentAt: hours(-0.2), isMe: false
                )
            ]
        default:
            []
        }
    }

    /// 「我的」冷启动也有可读内容
    static let seedBookingRecords: [BuddyBookingRecord] = [
        BuddyBookingRecord(
            id: uid(901), companionNickname: "阿凯", hours: 2,
            scheduledAt: day(2, hour: 20), bookedAt: hours(-48),
            priceText: "¥256", status: .paid, paymentMethod: "余额支付",
            paidAt: hours(-47)
        ),
        BuddyBookingRecord(
            id: uid(902), companionNickname: "小周", hours: 3,
            scheduledAt: day(-3, hour: 18, minute: 30), bookedAt: hours(-120),
            priceText: "¥414", status: .completed, paymentMethod: "余额支付",
            paidAt: hours(-119), completedAt: hours(-96)
        ),
        BuddyBookingRecord(
            id: uid(903), companionNickname: "阿凯", hours: 1,
            scheduledAt: day(1, hour: 15), bookedAt: hours(-2),
            priceText: "¥128", status: .awaitingPayment, paymentMethod: "simulated"
        ),
        BuddyBookingRecord(
            id: uid(904), companionNickname: "小周", hours: 2,
            scheduledAt: day(0, hour: 19), bookedAt: hours(-6),
            priceText: "¥256", status: .inProgress, paymentMethod: "余额支付",
            paidAt: hours(-5), selectedSlotLabel: "今晚 · 2 小时"
        ),
        BuddyBookingRecord(
            id: uid(905), companionNickname: "阿凯", hours: 1,
            scheduledAt: day(3, hour: 14), bookedAt: hours(-1),
            priceText: "¥138", status: .pendingConfirm, paymentMethod: "simulated"
        ),
        // 预览轨第 4 张：已支付未履约
        BuddyBookingRecord(
            id: uid(906), companionNickname: "小周", hours: 2,
            scheduledAt: day(4, hour: 16), bookedAt: hours(-12),
            priceText: "¥256", status: .paid, paymentMethod: "余额支付",
            paidAt: hours(-11), selectedSlotLabel: "周末下午 · 2 小时"
        )
    ]

    static let seedInviteRecords: [BuddyInviteRecord] = [
        BuddyInviteRecord(
            id: uid(911), nickname: "Mia", activityTitle: "思南公馆咖啡漫谈",
            sentAt: hours(-20), status: .accepted
        ),
        BuddyInviteRecord(
            id: uid(912), nickname: "Leo", activityTitle: "羽毛球混双打野",
            sentAt: hours(-10), status: .pending
        ),
        BuddyInviteRecord(
            id: uid(913), nickname: "小周", activityTitle: "外滩骑行夜游",
            sentAt: hours(-36), status: .declined
        )
    ]
}
