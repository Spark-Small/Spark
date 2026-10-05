//
//  ActivityComposeDraft.swift
//  坐标系
//
//  发起活动草稿：单页必要字段 + 最多 6 张照片/视频（首张为封面）。
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

/// 收费方式：免费 · 预付 · 现场 AA。
enum ActivityComposeFeeKind: String, CaseIterable, Identifiable {
    case free
    case paid
    case venueAA

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: ActivityCardStatus.free
        case .paid: ActivityComposeCopy.feeKindPaid
        case .venueAA: ActivityComposeCopy.feeKindAA
        }
    }

    var systemImage: String {
        switch self {
        case .free: "gift"
        case .paid: "yensign.circle"
        case .venueAA: "person.2"
        }
    }

    static func infer(from fee: String) -> ActivityComposeFeeKind {
        if Activity.isVenueSelfPayFee(fee) { return .venueAA }
        let trimmed = fee.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty
            || trimmed.contains(ActivityCardStatus.free)
            || trimmed.caseInsensitiveCompare(ActivityCardStatus.free) == .orderedSame
        {
            return .free
        }
        return .paid
    }
}

@MainActor
@Observable
final class ActivityComposeDraft {
    static let maxMediaCount = ActivityComposeCopy.maxMediaCount

    var title = ""
    var category: ActivityCategory = .outdoorSports
    var location = ""
    var date = Date().addingTimeInterval(3600 * 6)
    /// 静默默认：开始后 2 小时；不在主路径展示。
    var endDate = Date().addingTimeInterval(3600 * 8)
    var capacity = 8
    var feeKind: ActivityComposeFeeKind = .free
    var feeAmountText = ""
    var feeAAEstimateText = ""
    var summary = ""
    /// 编辑时保留原标签；发起页不再编辑标签。
    var tags: [String] = []
    /// 有序媒体：首张为封面，其余写入详情相册。最多 `maxMediaCount`。
    var mediaNames: [String] = []
    var baselineMediaNames: [String] = []
    var mediaPreviews: [String: UIImage] = [:]
    var mediaPickerItems: [PhotosPickerItem] = []
    var latitude: Double?
    var longitude: Double?
    var isPreparingMedia = false
    var moderationAlert: String?

    /// 跨文件扩展（`+Persistence` / `+Media`）读写，故非 `private`。
    var editingActivityID: Activity.ID?
    var didPrefill = false
    var editingBaseline: FieldSnapshot?
    /// 新建预览用稳定 id，避免每次打开预览换封面种子。
    private let previewSessionID = UUID()

    var isEditing: Bool { editingActivityID != nil }

    var publishCategories: [ActivityCategory] {
        ActivityCategory.allCases.filter { !$0.isBrowseAggregate }
    }

    var localCoverName: String? { mediaNames.first }

    var galleryPhotoNames: [String] { Array(mediaNames.dropFirst()) }

    var canAddMedia: Bool {
        mediaNames.count < Self.maxMediaCount && !isPreparingMedia
    }

    var remainingMediaSlots: Int {
        max(0, Self.maxMediaCount - mediaNames.count)
    }

    func isVideo(_ name: String) -> Bool {
        LocalMediaLibrary.isVideo(name: name)
    }

    var resolvedFee: String {
        switch feeKind {
        case .free:
            return ActivityCardStatus.free
        case .venueAA:
            let estimate = feeAAEstimateText.trimmingCharacters(in: .whitespacesAndNewlines)
            if estimate.isEmpty { return ActivityComposeCopy.feeResolvedVenueAA }
            return ActivityComposeCopy.feeResolvedVenueAAPrefix + estimate
        case .paid:
            let raw = feeAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else { return ActivityComposeCopy.feeResolvedPending }
            if raw.contains("¥") || raw.contains("￥") || raw.contains("元") || raw.contains("/") {
                return raw
            }
            return "¥\(raw)" + ActivityComposeCopy.feeResolvedPaidSuffix
        }
    }

    var canPublish: Bool {
        publishBlockers.isEmpty
    }

    /// 发布被拦住的原因（用于 Form footer 提示缺项）。
    var publishBlockers: [String] {
        var blockers: [String] = []
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blockers.append(ActivityComposeCopy.blockerTitle)
        }
        if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blockers.append(ActivityComposeCopy.blockerLocation)
        }
        if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blockers.append(ActivityComposeCopy.blockerSummary)
        }
        if isPreparingMedia {
            blockers.append(ActivityComposeCopy.blockerMedia)
        }
        if feeKind == .paid,
           feeAmountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blockers.append(ActivityComposeCopy.blockerFeeAmount)
        }
        return blockers
    }

    var publishBlockerFooter: String? {
        guard !publishBlockers.isEmpty else { return nil }
        return ActivityComposeCopy.publishBlockedPrefix + publishBlockers.joined(separator: "、")
    }

    /// 取消时是否值得落盘草稿（仅新建）。
    var shouldPersistDraftOnCancel: Bool {
        guard !isEditing else { return false }
        return currentFieldSnapshot.hasMeaningfulContent && !isPreparingMedia
    }

    /// 编辑态相对预填是否有未保存改动；新建态等价于「值得存草稿」。
    var isDirty: Bool {
        if isEditing {
            guard let editingBaseline else { return false }
            return currentFieldSnapshot != editingBaseline
        }
        return shouldPersistDraftOnCancel
    }

    var makePayload: ActivityComposePayload {
        ActivityComposePayload(
            title: title,
            category: category,
            location: location,
            date: date,
            capacity: capacity,
            fee: resolvedFee,
            summary: summary,
            tags: tags,
            localCoverName: localCoverName,
            latitude: latitude,
            longitude: longitude
        )
    }

    /// 发布预览用：现场 AA 约价会写入详情 hostNote，预览需同构展示。
    var previewHostNote: String? {
        guard feeKind == .venueAA else { return nil }
        let estimate = feeAAEstimateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !estimate.isEmpty else { return nil }
        return "现场大约人均 \(estimate)"
    }

    /// 构造对外详情同构的临时活动（未写入目录）。
    func makePreviewActivity(hostName: String, existing: Activity?) -> Activity {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let fee = resolvedFee

        if let existing {
            return Activity(
                id: existing.id,
                title: trimmedTitle,
                category: category,
                location: trimmedLocation,
                date: date,
                capacity: max(capacity, 2),
                joined: max(existing.joined, 1),
                hostName: existing.hostName,
                summary: trimmedSummary,
                fee: fee,
                tags: tags.isEmpty ? existing.tags : tags,
                distanceKM: existing.distanceKM,
                localCoverName: localCoverName,
                participantNames: existing.participantNames.isEmpty
                    ? [existing.hostName]
                    : existing.participantNames,
                latitude: latitude,
                longitude: longitude,
                relatedCircleID: existing.relatedCircleID
            )
        }

        return Activity(
            id: previewSessionID,
            title: trimmedTitle,
            category: category,
            location: trimmedLocation,
            date: date,
            capacity: max(capacity, 2),
            joined: 1,
            hostName: hostName,
            summary: trimmedSummary,
            fee: fee,
            tags: tags,
            distanceKM: 1.5,
            localCoverName: localCoverName,
            participantNames: [hostName],
            latitude: latitude,
            longitude: longitude
        )
    }

    func syncEndDate() {
        endDate = date.addingTimeInterval(3600 * 2)
    }

    func moderationBlockReason() -> String? {
        let combined = [title, summary, location, feeAmountText, feeAAEstimateText]
            .joined(separator: "\n")
        if case .block(let reason) = ContentModeration.scanText(combined) {
            return reason
        }
        return nil
    }

    // MARK: - Private

    struct FieldSnapshot: Equatable {
        var title: String
        var category: ActivityCategory
        var location: String
        var date: Date
        var capacity: Int
        var feeKind: ActivityComposeFeeKind
        var feeAmountText: String
        var feeAAEstimateText: String
        var summary: String
        var mediaNames: [String]
        var latitude: Double?
        var longitude: Double?

        var hasMeaningfulContent: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !feeAmountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !feeAAEstimateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !mediaNames.isEmpty
        }
    }

    var currentFieldSnapshot: FieldSnapshot {
        FieldSnapshot(
            title: title,
            category: category,
            location: location,
            date: date,
            capacity: capacity,
            feeKind: feeKind,
            feeAmountText: feeAmountText,
            feeAAEstimateText: feeAAEstimateText,
            summary: summary,
            mediaNames: mediaNames,
            latitude: latitude,
            longitude: longitude
        )
    }

}
