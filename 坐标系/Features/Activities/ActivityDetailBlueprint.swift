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

    // MARK: - Assembly & section priority

    static func assemble(
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
    static func applyOverrides(
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
    static func rankVisibleSections(
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

    static func hasRailContent(_ id: ActivityDetailSectionID, blueprint: ActivityDetailBlueprint) -> Bool {
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

    static func railPriority(
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

    static func registrationNotes(extras: [String] = []) -> [String] {
        extras + [
            "请使用真实昵称，便于发起人现场核验",
            "\(ActivityCardStatus.fullVerbose)时可加入候补，有人取消后将按顺序通知",
            "参加成功后将自动加入活动群，接收集合与变更通知",
            "如需取消，请在活动开始前操作；无故缺席可能影响后续参加"
        ]
    }

    static func outdoorTimeline(_ a: Activity) -> [ActivityDetailTimelineItem] {
        [
            .init(time: timeOffset(a, minutes: 0), title: "集合会合", detail: "在 \(a.location) 清点人数并进行热身"),
            .init(time: timeOffset(a, minutes: 20), title: "正式出发", detail: "按规划路线或场地开始活动"),
            .init(time: timeOffset(a, minutes: 90), title: "中途休息", detail: "补水调整，请根据自身状态量力而行"),
            .init(time: timeOffset(a, minutes: 150), title: "活动结束", detail: "合影留念，在附近交通便利处散场")
        ]
    }

    static func timeOffset(_ activity: Activity, minutes: Int) -> String {
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
