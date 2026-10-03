//
//  ActivityDetailBlueprint.swift
//  坐标系
//
//  按 ActivityCategory 派生详情分区；按内容与决策优先级排序可见 Section。
//

import Foundation
import CoordinateModels

enum ActivityDetailSectionID: String, Hashable, CaseIterable {
    case plan
    case fee
    case prep
    case notes
}

struct ActivityDetailTimelineItem: Hashable, Identifiable {
    var id: String { "\(time)-\(title)" }
    let time: String
    let title: String
    let detail: String
}

struct ActivityDetailChecklistItem: Hashable, Identifiable {
    var id: String { text }
    let text: String
    let included: Bool
}

struct ActivityDetailGearItem: Hashable, Identifiable {
    var id: String { title }
    let title: String
    let detail: String
    let systemImage: String
}

struct ActivityDetailSection: Identifiable, Hashable {
    let id: ActivityDetailSectionID
    let title: String
}

struct ActivityDetailBlueprint {
    /// 按用户关心优先级排序后的可见分区
    let sections: [ActivityDetailSection]
    let timeline: [ActivityDetailTimelineItem]
    let feeIncluded: [ActivityDetailChecklistItem]
    let feeExcluded: [ActivityDetailChecklistItem]
    let refundNotes: [String]
    let gear: [ActivityDetailGearItem]
    let prepNotes: [String]
    let registrationNotes: [String]
    /// 发起人本地补充说明（可覆盖）
    let hostNote: String?

    @MainActor
    static func make(for activity: Activity) -> ActivityDetailBlueprint {
        applyOverrides(templateBlueprint(for: activity), activity: activity)
    }

    /// 发起人是否本地覆盖了该分区（预览用：未覆盖则展示「待补充」，不拿模板冒充）。
    @MainActor
    static func hasHostAuthoredContent(for id: ActivityDetailSectionID, activity: Activity) -> Bool {
        guard let override = ActivityDetailContentStore.override(for: activity.id) else {
            return false
        }
        switch id {
        case .plan:
            return !(override.timeline?.isEmpty ?? true)
        case .fee:
            let hasIncluded = !(override.feeIncluded?.isEmpty ?? true)
            let hasExcluded = !(override.feeExcluded?.isEmpty ?? true)
            let hasRefund = !(override.refundNotes?.isEmpty ?? true)
            return hasIncluded || hasExcluded || hasRefund
        case .prep:
            let hasGear = !(override.gear?.isEmpty ?? true)
            let hasNotes = !(override.prepNotes?.isEmpty ?? true)
            return hasGear || hasNotes
        case .notes:
            return !(override.registrationNotes?.isEmpty ?? true)
        }
    }

    static func templateBlueprint(for activity: Activity) -> ActivityDetailBlueprint {
        switch activity.category {
        case .outdoorSports:
            return outdoor(activity)
        case .food:
            return food(activity)
        case .interestSocial:
            return social(activity)
        case .cityExplore:
            return cityExplore(activity)
        case .handmade:
            return handmade(activity)
        case .learning:
            return learning(activity)
        case .entertainment:
            return entertainment(activity)
        case .all, .forYou:
            return social(activity)
        }
    }

    // MARK: - Outdoor（装备与风险）

    private static func outdoor(_ a: Activity) -> ActivityDetailBlueprint {
        return assemble(
            activity: a,
            sectionTemplates: [
                .init(id: .plan, title: ActivityDetailCopy.timelineEditorTitle),
                .init(id: .fee, title: ActivityDetailCopy.feeSectionTitle),
                .init(id: .prep, title: "装备与风险"),
                .init(id: .notes, title: ActivityDetailCopy.joinNoticesHeader)
            ],
            timeline: outdoorTimeline(a),
            feeIncluded: [
                .init(text: "活动组织与现场协调", included: true),
                .init(text: a.isFree ? "本场免费参与" : "活动组织费用（见上方报价）", included: true),
                .init(text: "公共物资与基础路线指引", included: true)
            ],
            feeExcluded: [
                .init(text: "个人往返交通（未特别说明含车时）", included: false),
                .init(text: "餐食与个人消费", included: false),
                .init(text: "因个人原因中途退出的相关损失", included: false)
            ],
            refundNotes: [
                "活动开始前 24 小时取消：可全额取消参加",
                "活动开始前 6 小时内取消：名额可能无法释放，请尽量提前",
                "活动开始后离队：视为已参与，名额不支持转让"
            ],
            gear: [
                .init(title: "鞋", detail: "防滑运动鞋或徒步鞋，避免拖鞋、高跟鞋", systemImage: "shoeprints.fill"),
                .init(title: "衣服", detail: "透气速干，建议洋葱式穿脱", systemImage: "tshirt"),
                .init(title: "补给", detail: "自备饮水 1–1.5L 与少量能量零食", systemImage: "drop"),
                .init(title: "其他", detail: "充电宝、防晒、轻便外套按天气准备", systemImage: "backpack")
            ],
            prepNotes: [
                "户外活动受天气与地形影响，请根据自身情况量力而行",
                "患有心脏病、严重哮喘等不宜剧烈运动者请勿参加",
                "请勿擅自离队，集合后请听从发起人现场安排",
                "建议自行购买户外运动意外险"
            ],
            registrationNotes: registrationNotes(
                extras: ["适合人群：有基础体能即可，新手请量力选择轻松场次"]
            )
        )
    }

    // MARK: - Food（用餐安排 / 口味与忌口）

    private static func food(_ a: Activity) -> ActivityDetailBlueprint {
        assemble(
            activity: a,
            sectionTemplates: [
                .init(id: .plan, title: "用餐安排"),
                .init(id: .fee, title: ActivityDetailCopy.feeSectionTitle),
                .init(id: .prep, title: "口味与忌口"),
                .init(id: .notes, title: ActivityDetailCopy.joinNoticesHeader)
            ],
            timeline: [
                .init(time: timeOffset(a, minutes: 0), title: "门口会合", detail: "在 \(a.location) 碰面，清点人数并确认订位"),
                .init(time: timeOffset(a, minutes: 10), title: "入座寒暄", detail: "落座后简单自我介绍，沟通忌口与口味偏好"),
                .init(time: timeOffset(a, minutes: 25), title: "点餐开吃", detail: "按人数与预算点餐，可分享推荐菜"),
                .init(time: timeOffset(a, minutes: 100), title: "结账散场", detail: "费用按说明结算；可自愿续聊或各自离开")
            ],
            feeIncluded: [
                .init(text: "订位协调与拼桌安排", included: true),
                .init(text: a.isFree ? "餐费现场 AA 结算" : "活动页标注的套餐或席位费用", included: true)
            ],
            feeExcluded: [
                .init(text: "酒水、加菜、甜品等额外消费", included: false),
                .init(text: "个人往返交通与停车费", included: false)
            ],
            refundNotes: [
                "开餐前 4 小时取消：可释放名额",
                "已订位临期无故缺席：可能影响后续活动参加资格"
            ],
            gear: [],
            prepNotes: [
                "如有食物过敏、宗教或饮食禁忌，请提前私信发起人",
                "高峰时段可能排队或等位，请预留 15–30 分钟缓冲",
                "请尊重店员与同桌伙伴，避免长时间占座或大声喧哗",
                "如需分开结账，请提前与发起人沟通"
            ],
            registrationNotes: registrationNotes(
                extras: ["适合人群：喜欢一起吃饭聊天的朋友，不限厨艺基础"]
            )
        )
    }

    // MARK: - Social（活动流程 / 见面前准备）

    private static func social(_ a: Activity) -> ActivityDetailBlueprint {
        assemble(
            activity: a,
            sectionTemplates: [
                .init(id: .plan, title: "活动流程"),
                .init(id: .fee, title: ActivityDetailCopy.feeSectionTitle),
                .init(id: .prep, title: "见面前准备"),
                .init(id: .notes, title: ActivityDetailCopy.joinNoticesHeader)
            ],
            timeline: [
                .init(time: timeOffset(a, minutes: 0), title: "签到集合", detail: "在 \(a.location) 与发起人 \(a.hostName) 会合"),
                .init(time: timeOffset(a, minutes: 15), title: "破冰介绍", detail: "轮流自我介绍，分享近期状态或兴趣标签"),
                .init(time: timeOffset(a, minutes: 45), title: "主题交流", detail: "按兴趣自由组队深入聊，可换桌换组"),
                .init(time: timeOffset(a, minutes: 100), title: "轻松收尾", detail: "合影可选；自愿交换联系方式，尊重个人意愿")
            ],
            feeIncluded: [
                .init(text: "活动组织与场地协调", included: true),
                .init(text: a.isFree ? "场地费用按活动说明结算" : "费用含基础席位", included: true)
            ],
            feeExcluded: [
                .init(text: "个人额外饮品或小吃消费", included: false),
                .init(text: "个人往返交通", included: false)
            ],
            refundNotes: [
                "活动开始前 6 小时取消：可释放参加名额",
                "临期缺席会影响候补伙伴的参与机会，请尽量提前取消"
            ],
            gear: [],
            prepNotes: [
                "可准备一个想聊的话题，或最近在读的书、看过的展",
                "尊重他人边界，不强行推销、撮合或索取联系方式",
                "建议手机静音，专注在场交流",
                "如有社交焦虑或需要低互动场次，可提前告知发起人"
            ],
            registrationNotes: registrationNotes(
                extras: ["适合人群：想认识新朋友、愿意真诚交流的伙伴"]
            )
        )
    }

    // MARK: - City explore（探索路线 / 出行准备）

    private static func cityExplore(_ a: Activity) -> ActivityDetailBlueprint {
        assemble(
            activity: a,
            sectionTemplates: [
                .init(id: .plan, title: "探索路线"),
                .init(id: .fee, title: ActivityDetailCopy.feeSectionTitle),
                .init(id: .prep, title: "出行准备"),
                .init(id: .notes, title: ActivityDetailCopy.joinNoticesHeader)
            ],
            timeline: [
                .init(time: timeOffset(a, minutes: 0), title: "起点集合", detail: "在 \(a.location) 集合，确认路线、时长与注意事项"),
                .init(time: timeOffset(a, minutes: 15), title: "开场说明", detail: "简要介绍本场看点与集合暗号"),
                .init(time: timeOffset(a, minutes: 40), title: "第一站", detail: "参观 / 拍摄；掉队请及时在群内喊一声"),
                .init(time: timeOffset(a, minutes: 100), title: "中途休整", detail: "补水小歇，确认下一站与预计结束时间"),
                .init(time: timeOffset(a, minutes: 160), title: "终点解散", detail: "在附近交通便利处散场，可自愿合影")
            ],
            feeIncluded: [
                .init(text: "路线组织与现场讲解", included: true),
                .init(text: a.isFree ? "本场组织免费" : "活动组织费用（见上方报价）", included: true)
            ],
            feeExcluded: [
                .init(text: "公共交通、打车与景点门票", included: false),
                .init(text: "餐食、咖啡与个人消费", included: false)
            ],
            refundNotes: [
                "活动开始前 12 小时取消：可释放参加名额",
                "已购门票类场次：退票规则以票务方为准"
            ],
            gear: [
                .init(title: "鞋", detail: "舒适防滑的步行鞋，预计行走较多", systemImage: "shoeprints.fill"),
                .init(title: "补给", detail: "随身饮用水与少量零食", systemImage: "cup.and.saucer"),
                .init(title: "防晒", detail: "帽子、防晒用品按天气准备", systemImage: "sun.max"),
                .init(title: "雨具", detail: "雨天请自备折叠伞或轻便雨衣", systemImage: "cloud.rain")
            ],
            prepNotes: [
                "请勿长时间脱离队伍；掉队请及时在群内告知位置",
                "请遵守景区、展馆与社区相关规定，文明拍照",
                "体力不支可随时告知发起人，可中途提前离开",
                "建议开启定位共享（自愿），方便集合"
            ],
            registrationNotes: registrationNotes(
                extras: ["适合人群：喜欢城市漫游、愿意步行探索的朋友"]
            )
        )
    }

    // MARK: - Handmade（体验流程 / 材料与自备）

    private static func handmade(_ a: Activity) -> ActivityDetailBlueprint {
        assemble(
            activity: a,
            sectionTemplates: [
                .init(id: .plan, title: "体验流程"),
                .init(id: .fee, title: ActivityDetailCopy.feeSectionTitle),
                .init(id: .prep, title: "材料与自备"),
                .init(id: .notes, title: ActivityDetailCopy.joinNoticesHeader)
            ],
            timeline: [
                .init(time: timeOffset(a, minutes: 0), title: "签到领料", detail: "在 \(a.location) 签到并领取材料包 / 工位"),
                .init(time: timeOffset(a, minutes: 15), title: "示范讲解", detail: "发起人演示关键步骤、工具用法与安全注意"),
                .init(time: timeOffset(a, minutes: 40), title: "动手制作", detail: "自由创作，可互相交流请教；按需个别指导"),
                .init(time: timeOffset(a, minutes: 110), title: "收尾合影", detail: "清理工位，成品拍照；可带走或按说明养护")
            ],
            feeIncluded: [
                .init(text: "基础材料包", included: true),
                .init(text: "场地、工具与基础指导", included: true)
            ],
            feeExcluded: [
                .init(text: "升级材料、额外配件与加时", included: false),
                .init(text: "个人往返交通", included: false)
            ],
            refundNotes: [
                "活动开始前 24 小时取消：可释放材料预留名额",
                "材料已开封或体验已开始：费用一般不支持退还"
            ],
            gear: [
                .init(title: "围裙", detail: "建议自备围裙或旧衣物，防止弄脏", systemImage: "paintbrush.pointed"),
                .init(title: "收纳", detail: "自备手提袋，方便带走成品", systemImage: "bag"),
                .init(title: "发型", detail: "长发请束起，便于操作与安全", systemImage: "scissors")
            ],
            prepNotes: [
                "注意刀具、热源与化学品使用安全，听从现场指引",
                "未完全干透 / 定型的作品请小心搬运",
                "未成年人需监护人全程陪同",
                "过敏体质请提前确认材料成分（如香薰、胶水）"
            ],
            registrationNotes: registrationNotes(
                extras: ["适合人群：零基础可参加，喜欢动手创作即可"]
            )
        )
    }

    // MARK: - Learning（议程安排 / 课前准备）

    private static func learning(_ a: Activity) -> ActivityDetailBlueprint {
        assemble(
            activity: a,
            sectionTemplates: [
                .init(id: .plan, title: "议程安排"),
                .init(id: .fee, title: ActivityDetailCopy.feeSectionTitle),
                .init(id: .prep, title: "课前准备"),
                .init(id: .notes, title: ActivityDetailCopy.joinNoticesHeader)
            ],
            timeline: [
                .init(time: timeOffset(a, minutes: 0), title: "签到入座", detail: "在 \(a.location) 签到并就座，调试设备"),
                .init(time: timeOffset(a, minutes: 10), title: "主题导入", detail: "介绍分享目标、议程与适合听讲人群"),
                .init(time: timeOffset(a, minutes: 35), title: "核心讲解", detail: "案例分享与实操演示"),
                .init(time: timeOffset(a, minutes: 75), title: "练习与问答", detail: "现场练习或开放提问，鼓励讨论"),
                .init(time: timeOffset(a, minutes: 105), title: "总结散场", detail: "回顾要点；讲义 / 资料按活动说明发放")
            ],
            feeIncluded: [
                .init(text: "主题分享与基础讲义 / 资料", included: true),
                .init(text: "场地席位", included: true)
            ],
            feeExcluded: [
                .init(text: "延伸付费课程、一对一辅导或进阶资料", included: false),
                .init(text: "个人设备与软件订阅费用", included: false)
            ],
            refundNotes: [
                "活动开始前 12 小时取消：可释放参加名额",
                "已发放不可撤回的数字资料后：退费规则以发起人说明为准"
            ],
            gear: [
                .init(title: "笔记", detail: "笔记本、平板或电脑，便于记录", systemImage: "book"),
                .init(title: "充电", detail: "电子设备请确保电量充足，可带充电宝", systemImage: "battery.100"),
                .init(title: "耳机", detail: "若为线上连麦场次，建议自备耳机麦克风", systemImage: "headphones")
            ],
            prepNotes: [
                "提问请简洁明确，便于更多伙伴参与交流",
                "未经发起人允许，请勿公开传播录音、录像或讲义",
                "迟到超过 20 分钟可能影响完整体验，请尽量准时",
                "如需电脑实操，请提前安装活动说明中的软件"
            ],
            registrationNotes: registrationNotes(
                extras: ["适合人群：对该主题感兴趣即可；有无基础以活动介绍为准"]
            )
        )
    }

    // MARK: - Entertainment（活动流程 / 玩法与规则）

    private static func entertainment(_ a: Activity) -> ActivityDetailBlueprint {
        assemble(
            activity: a,
            sectionTemplates: [
                .init(id: .plan, title: "活动流程"),
                .init(id: .fee, title: ActivityDetailCopy.feeSectionTitle),
                .init(id: .prep, title: "玩法与规则"),
                .init(id: .notes, title: ActivityDetailCopy.joinNoticesHeader)
            ],
            timeline: [
                .init(time: timeOffset(a, minutes: 0), title: "集合签到", detail: "在 \(a.location) 签到，确认人数与桌位 / 房间"),
                .init(time: timeOffset(a, minutes: 10), title: "规则说明", detail: "介绍玩法、时长与新手友好程度；可现场答疑"),
                .init(time: timeOffset(a, minutes: 25), title: "正式开玩", detail: "按分组、桌位或剧本角色开始"),
                .init(time: timeOffset(a, minutes: 100), title: "中场休整", detail: "可补水、换场或加钟（按场馆规则）"),
                .init(time: timeOffset(a, minutes: 160), title: "结算散场", detail: "费用按活动说明结算后散场，可自愿续摊")
            ],
            feeIncluded: [
                .init(text: a.isFree ? "活动组织协调（台费 / 门票现场 AA）" : "活动页标注费用（含基础场次）", included: true),
                .init(text: "基础规则讲解与组局协调", included: true)
            ],
            feeExcluded: [
                .init(text: "加钟、饮料、小费及其他个人消费", included: false),
                .init(text: "个人往返交通与停车费", included: false)
            ],
            refundNotes: [
                "活动开始前 6 小时取消：可释放参加名额",
                "已锁房 / 已开剧本的场次：退改规则以场馆或发起人说明为准",
                "临期无故缺席：可能影响候补伙伴的参与安排"
            ],
            gear: [],
            prepNotes: [
                "尊重输赢与角色扮演，禁止人身攻击、性别歧视或不友善行为",
                "请避免电子设备外放，影响他人沉浸体验",
                "未成年人参与请确认场馆年龄与监护规定",
                "桌游 / 剧本杀新手欢迎；若有剧透雷点可提前私信发起人",
                "KTV / 电竞场次请爱护设备，按场馆规定使用"
            ],
            registrationNotes: registrationNotes(
                extras: ["适合人群：想轻松玩一局的朋友；新手友好程度见活动介绍"]
            )
        )
    }

    // MARK: - Assembly & section priority

    private static func assemble(
        activity: Activity,
        sectionTemplates: [ActivityDetailSection],
        timeline: [ActivityDetailTimelineItem],
        feeIncluded: [ActivityDetailChecklistItem],
        feeExcluded: [ActivityDetailChecklistItem],
        refundNotes: [String],
        gear: [ActivityDetailGearItem],
        prepNotes: [String],
        registrationNotes: [String]
    ) -> ActivityDetailBlueprint {
        let draft = ActivityDetailBlueprint(
            sections: sectionTemplates,
            timeline: timeline,
            feeIncluded: feeIncluded,
            feeExcluded: feeExcluded,
            refundNotes: refundNotes,
            gear: gear,
            prepNotes: prepNotes,
            registrationNotes: registrationNotes,
            hostNote: nil
        )
        let ranked = rankVisibleSections(templates: sectionTemplates, blueprint: draft, activity: activity)
        return ActivityDetailBlueprint(
            sections: ranked,
            timeline: timeline,
            feeIncluded: feeIncluded,
            feeExcluded: feeExcluded,
            refundNotes: refundNotes,
            gear: gear,
            prepNotes: prepNotes,
            registrationNotes: registrationNotes,
            hostNote: nil
        )
    }

    /// 本地写实覆盖优先于类别模板
    @MainActor
    private static func applyOverrides(
        _ base: ActivityDetailBlueprint,
        activity: Activity
    ) -> ActivityDetailBlueprint {
        guard let override = ActivityDetailContentStore.override(for: activity.id) else {
            return base
        }

        let timeline: [ActivityDetailTimelineItem]
        if let items = override.timeline, !items.isEmpty {
            timeline = items.map {
                ActivityDetailTimelineItem(time: $0.time, title: $0.title, detail: $0.detail)
            }
        } else {
            timeline = base.timeline
        }

        let feeIncluded = override.feeIncluded.map {
            $0.map { ActivityDetailChecklistItem(text: $0, included: true) }
        } ?? base.feeIncluded

        let feeExcluded = override.feeExcluded.map {
            $0.map { ActivityDetailChecklistItem(text: $0, included: false) }
        } ?? base.feeExcluded

        let gear: [ActivityDetailGearItem]
        if let items = override.gear, !items.isEmpty {
            gear = items.map {
                ActivityDetailGearItem(title: $0.title, detail: $0.detail, systemImage: $0.systemImage)
            }
        } else {
            gear = base.gear
        }

        let merged = ActivityDetailBlueprint(
            sections: base.sections,
            timeline: timeline,
            feeIncluded: feeIncluded,
            feeExcluded: feeExcluded,
            refundNotes: override.refundNotes ?? base.refundNotes,
            gear: gear,
            prepNotes: override.prepNotes ?? base.prepNotes,
            registrationNotes: override.registrationNotes ?? base.registrationNotes,
            hostNote: override.hostNote
        )
        let ranked = rankVisibleSections(templates: base.sections, blueprint: merged, activity: activity)
        return ActivityDetailBlueprint(
            sections: ranked,
            timeline: merged.timeline,
            feeIncluded: merged.feeIncluded,
            feeExcluded: merged.feeExcluded,
            refundNotes: merged.refundNotes,
            gear: merged.gear,
            prepNotes: merged.prepNotes,
            registrationNotes: merged.registrationNotes,
            hostNote: merged.hostNote
        )
    }

    /// 按内容是否存在 + 用户决策优先级排序可见分区
    private static func rankVisibleSections(
        templates: [ActivityDetailSection],
        blueprint: ActivityDetailBlueprint,
        activity: Activity
    ) -> [ActivityDetailSection] {
        templates
            .filter { hasRailContent($0.id, blueprint: blueprint) }
            .sorted { lhs, rhs in
                let lp = railPriority(for: lhs.id, activity: activity, blueprint: blueprint)
                let rp = railPriority(for: rhs.id, activity: activity, blueprint: blueprint)
                if lp != rp { return lp > rp }
                return lhs.id.rawValue < rhs.id.rawValue
            }
    }

    private static func hasRailContent(_ id: ActivityDetailSectionID, blueprint: ActivityDetailBlueprint) -> Bool {
        switch id {
        case .plan:
            return !blueprint.timeline.isEmpty
        case .fee:
            return !blueprint.feeIncluded.isEmpty
                || !blueprint.feeExcluded.isEmpty
                || !blueprint.refundNotes.isEmpty
        case .prep:
            return !blueprint.gear.isEmpty || !blueprint.prepNotes.isEmpty
        case .notes:
            return !blueprint.registrationNotes.isEmpty
        }
    }

    private static func railPriority(
        for id: ActivityDetailSectionID,
        activity: Activity,
        blueprint: ActivityDetailBlueprint
    ) -> Int {
        switch id {
        case .plan:
            var score = 84
            switch activity.category {
            case .food, .outdoorSports, .cityExplore: score += 6
            case .interestSocial: score -= 4
            default: break
            }
            return score

        case .fee:
            if activity.isFree {
                return activity.category == .food ? 58 : 42
            }
            var score = 78
            if !blueprint.refundNotes.isEmpty { score += 4 }
            return score

        case .prep:
            var score = 52
            if !blueprint.gear.isEmpty { score += 18 }
            switch activity.category {
            case .outdoorSports, .cityExplore, .handmade: score += 16
            case .entertainment: score += 12
            case .interestSocial: score += 4
            default: break
            }
            return score

        case .notes:
            return 34
        }
    }

    // MARK: - Shared helpers

    private static func registrationNotes(extras: [String] = []) -> [String] {
        extras + [
            "请使用真实昵称，便于发起人现场核验",
            "\(ActivityCardStatus.fullVerbose)时可加入候补，有人取消后将按顺序通知",
            "参加成功后将自动加入活动群，接收集合与变更通知",
            "如需取消，请在活动开始前操作；无故缺席可能影响后续参加"
        ]
    }

    private static func outdoorTimeline(_ a: Activity) -> [ActivityDetailTimelineItem] {
        [
            .init(time: timeOffset(a, minutes: 0), title: "集合会合", detail: "在 \(a.location) 清点人数并进行热身"),
            .init(time: timeOffset(a, minutes: 20), title: "正式出发", detail: "按规划路线或场地开始活动"),
            .init(time: timeOffset(a, minutes: 90), title: "中途休息", detail: "补水调整，请根据自身状态量力而行"),
            .init(time: timeOffset(a, minutes: 150), title: "活动结束", detail: "合影留念，在附近交通便利处散场")
        ]
    }

    private static func timeOffset(_ activity: Activity, minutes: Int) -> String {
        let date = activity.date.addingTimeInterval(TimeInterval(minutes * 60))
        return Formatters.shortTime.string(from: date)
    }

    /// 折叠分区标题下的单行摘要（帮助决策前快速扫读）
    static func sectionSummary(
        for id: ActivityDetailSectionID,
        activity: Activity,
        blueprint: ActivityDetailBlueprint
    ) -> String {
        switch id {
        case .plan:
            if blueprint.timeline.isEmpty { return "暂无行程安排" }
            let first = blueprint.timeline[0].title
            return blueprint.timeline.count > 1
                ? "\(blueprint.timeline.count) 个环节 · 首项 \(first)"
                : first
        case .fee:
            if activity.isFree { return "免费参加" }
            var parts: [String] = []
            if !blueprint.feeIncluded.isEmpty {
                parts.append("含 \(blueprint.feeIncluded.count) 项")
            }
            if !blueprint.refundNotes.isEmpty {
                parts.append("含退改说明")
            }
            return parts.isEmpty ? activity.fee : parts.joined(separator: " · ")
        case .prep:
            if !blueprint.gear.isEmpty {
                return "\(blueprint.gear.count) 项装备清单"
            }
            if let first = blueprint.prepNotes.first {
                return first
            }
            return "查看准备事项"
        case .notes:
            if blueprint.registrationNotes.isEmpty { return "暂无参加须知" }
            return "\(blueprint.registrationNotes.count) 条须知"
        }
    }
}
