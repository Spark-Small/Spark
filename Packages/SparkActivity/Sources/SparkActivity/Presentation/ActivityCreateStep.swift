// Module: SparkActivity — Create flow steps + weighted progress (orient → decide → understand).

import Foundation

/// Product narrative anchor for create-activity copy.
enum ActivityCreateBrandCopy {
    static let slogan = String(
        localized: "activity.create.slogan",
        defaultValue: "用真实线下局，认识可信的人",
        comment: "Spark create-activity brand line"
    )
}

/// Mirrors `ActivityDetailLoadedList` cognitive layers with user-facing step labels.
enum ActivityCreateStep: CaseIterable, Identifiable, Sendable {
    case orient
    case decide
    case understand

    var id: Self { self }

    var title: String {
        switch self {
        case .orient:
            String(localized: "activity.create.step.orient", defaultValue: "是什么局", comment: "Orient step")
        case .decide:
            String(localized: "activity.create.step.decide", defaultValue: "何时何地见", comment: "Decide step")
        case .understand:
            String(localized: "activity.create.step.understand", defaultValue: "更多说明", comment: "Understand step")
        }
    }

    var detailCounterpart: String {
        switch self {
        case .orient:
            String(
                localized: "activity.create.step.orient.detail",
                defaultValue: "封面 · 局名",
                comment: "Orient maps to cover + title"
            )
        case .decide:
            String(
                localized: "activity.create.step.decide.detail",
                defaultValue: "地点 · 时间 · 人数",
                comment: "Decide maps to schedule block"
            )
        case .understand:
            String(
                localized: "activity.create.step.understand.detail",
                defaultValue: "加分项",
                comment: "Optional understand bonus step"
            )
        }
    }

    /// Required publish milestones shown in the progress bar.
    static var requiredSteps: [ActivityCreateStep] {
        [.orient, .decide]
    }

    var isOptional: Bool {
        self == .understand
    }

    func isComplete(draft: CreateActivityDraft, hasCover: Bool) -> Bool {
        switch self {
        case .orient:
            let hasTitle = !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasCover && hasTitle
        case .decide:
            let location = !draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return location
        case .understand:
            return !draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func fillRatio(draft: CreateActivityDraft, hasCover: Bool) -> Double {
        switch self {
        case .orient:
            var ratio = 0.0
            if hasCover { ratio += 0.5 }
            if !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { ratio += 0.5 }
            return ratio
        case .decide:
            return draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1
        case .understand:
            return draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1
        }
    }
}

struct ActivityCreateProgressSnapshot: Sendable, Equatable {
    let requiredPercent: Int
    let segmentFill: [ActivityCreateStep: Double]
    let nextActionHint: String
    let isReadyToPreview: Bool

    static func make(draft: CreateActivityDraft, hasCover: Bool) -> ActivityCreateProgressSnapshot {
        let hasTitle = !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = !draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        var requiredPercent = 0
        if hasCover { requiredPercent += 35 }
        if hasTitle { requiredPercent += 35 }
        if hasLocation { requiredPercent += 30 }

        let segmentFill = Dictionary(
            uniqueKeysWithValues: ActivityCreateStep.allCases.map { step in
                (step, step.fillRatio(draft: draft, hasCover: hasCover))
            }
        )

        let nextActionHint: String = {
            if !hasCover {
                return String(
                    localized: "activity.create.progress.next.cover",
                    defaultValue: "下一步：上传局封面",
                    comment: "Next action cover"
                )
            }
            if !hasTitle {
                return String(
                    localized: "activity.create.progress.next.title",
                    defaultValue: "下一步：起个局名",
                    comment: "Next action title"
                )
            }
            if !hasLocation {
                return String(
                    localized: "activity.create.progress.next.location",
                    defaultValue: "下一步：填写集合地点",
                    comment: "Next action location"
                )
            }
            return String(
                localized: "activity.create.progress.next.preview",
                defaultValue: "可以预览成局了",
                comment: "Ready to preview"
            )
        }()

        return ActivityCreateProgressSnapshot(
            requiredPercent: min(requiredPercent, 100),
            segmentFill: segmentFill,
            nextActionHint: nextActionHint,
            isReadyToPreview: hasCover && hasTitle && hasLocation
        )
    }

    var percentLabel: String {
        String(
            format: String(
                localized: "activity.create.progress.percent.format",
                defaultValue: "成局进度 %lld%%",
                comment: "Progress percent; %lld is 0-100"
            ),
            locale: .current,
            requiredPercent
        )
    }
}
