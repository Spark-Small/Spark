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

    private(set) var editingActivityID: Activity.ID?
    private var didPrefill = false
    private var editingBaseline: FieldSnapshot?
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

    func removeMedia(at index: Int) {
        guard mediaNames.indices.contains(index) else { return }
        let name = mediaNames.remove(at: index)
        mediaPreviews.removeValue(forKey: name)
    }

    func prefill(from activity: Activity?) {
        guard !didPrefill else { return }
        didPrefill = true
        guard let activity else {
            syncEndDate()
            if let snapshot = ActivityComposeDraftStore.load() {
                apply(snapshot: snapshot)
            }
            return
        }

        editingActivityID = activity.id
        tags = activity.tags
        title = activity.title
        category = activity.category.isBrowseAggregate ? .outdoorSports : activity.category
        location = activity.location
        date = max(activity.date, Date())
        syncEndDate()
        capacity = max(activity.capacity, 2)
        summary = activity.summary
        latitude = activity.latitude
        longitude = activity.longitude

        var media: [String] = []
        if let cover = activity.localCoverName {
            media.append(cover)
        }
        let gallery = ActivityDetailContentStore.override(for: activity.id)?.galleryPhotoNames ?? []
        for name in gallery where !media.contains(name) {
            media.append(name)
            if media.count >= Self.maxMediaCount { break }
        }
        mediaNames = media
        baselineMediaNames = media
        Task { await hydrateMediaPreviews() }

        feeKind = ActivityComposeFeeKind.infer(from: activity.fee)
        switch feeKind {
        case .free:
            feeAmountText = ""
            feeAAEstimateText = ""
        case .venueAA:
            feeAmountText = ""
            feeAAEstimateText = Self.displayAAEstimate(from: activity.fee)
        case .paid:
            feeAmountText = Self.displayAmount(from: activity.fee)
            feeAAEstimateText = ""
        }

        editingBaseline = currentFieldSnapshot
    }

    /// 发布时只写入发起人真实内容（相册、AA 约价说明）。
    /// 行程 / 费用明细 / 准备 / 须知交给类别模板兜底，避免用稀疏默认覆盖完整模板。
    func persistContentOverride(for id: Activity.ID) {
        var override = ActivityDetailContentStore.override(for: id) ?? ActivityDetailContentOverride()

        if feeKind == .venueAA {
            let estimate = feeAAEstimateText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !estimate.isEmpty {
                let line = "现场大约人均 \(estimate)"
                if let existing = override.hostNote, !existing.isEmpty {
                    if !existing.contains("大约人均") {
                        override.hostNote = existing + "\n" + line
                    }
                } else {
                    override.hostNote = line
                }
            }
        }

        commitMediaRemovalsIfNeeded()
        let extras = galleryPhotoNames
        override.galleryPhotoNames = extras.isEmpty ? nil : extras

        ActivityDetailContentStore.save(override, for: id)
    }

    func discardUncommittedMediaIfNeeded() {
        LocalMediaLibrary.discardUncommitted(current: mediaNames, baseline: baselineMediaNames)
    }

    func commitMediaRemovalsIfNeeded() {
        LocalMediaLibrary.commitRemovals(current: mediaNames, baseline: baselineMediaNames)
        baselineMediaNames = mediaNames
    }

    func moderationBlockReason() -> String? {
        let combined = [title, summary, location, feeAmountText, feeAAEstimateText]
            .joined(separator: "\n")
        if case .block(let reason) = ContentModeration.scanText(combined) {
            return reason
        }
        return nil
    }

    func loadMedia(_ items: [PhotosPickerItem], actorKey: String) async {
        guard !items.isEmpty else { return }
        isPreparingMedia = true
        defer {
            isPreparingMedia = false
            mediaPickerItems = []
        }

        for item in items {
            guard mediaNames.count < Self.maxMediaCount else { break }
            guard let name = await LocalMediaLibrary.savePickerItem(item),
                  let url = LocalMediaLibrary.fileURL(named: name)
            else { continue }

            let preview: UIImage?
            if LocalMediaLibrary.isVideo(url: url) {
                preview = await LocalMediaLibrary.posterImage(for: url)
            } else {
                preview = await PlatformLocalImageCache.loadAsync(atPath: url.path)
            }
            guard let preview else {
                LocalMediaLibrary.delete(named: name)
                continue
            }

            let decision = await MediaModerationService.moderateImage(
                preview,
                context: .activityCover,
                actorKey: actorKey
            )
            if case .block(let reason) = decision {
                LocalMediaLibrary.delete(named: name)
                moderationAlert = reason
                continue
            }

            mediaNames.append(name)
            mediaPreviews[name] = preview
        }
    }

    @discardableResult
    func saveDraftSnapshot() -> Bool {
        guard shouldPersistDraftOnCancel else { return false }
        syncEndDate()
        let snapshot = ActivityComposeDraftSnapshot(
            title: title,
            categoryRaw: category.rawValue,
            location: location,
            date: date,
            endDate: endDate,
            capacity: capacity,
            feeKindRaw: feeKind.rawValue,
            feeAmountText: feeAmountText,
            feeAAEstimateText: feeAAEstimateText,
            summary: summary,
            tags: tags,
            localCoverName: localCoverName,
            galleryPhotoNames: galleryPhotoNames,
            latitude: latitude,
            longitude: longitude
        )
        ActivityComposeDraftStore.save(snapshot)
        baselineMediaNames = mediaNames
        return true
    }

    func clearDraftStoreAfterPublish() {
        ActivityComposeDraftStore.clear()
    }

    // MARK: - Private

    private struct FieldSnapshot: Equatable {
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

    private var currentFieldSnapshot: FieldSnapshot {
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

    private func apply(snapshot: ActivityComposeDraftSnapshot) {
        title = snapshot.title
        if let category = ActivityCategory(rawValue: snapshot.categoryRaw), !category.isBrowseAggregate {
            self.category = category
        }
        location = snapshot.location
        date = max(snapshot.date, Date())
        endDate = max(snapshot.endDate, date.addingTimeInterval(3600 * 2))
        capacity = min(max(snapshot.capacity, 2), 40)
        feeKind = ActivityComposeFeeKind(rawValue: snapshot.feeKindRaw) ?? .free
        feeAmountText = snapshot.feeAmountText
        feeAAEstimateText = snapshot.feeAAEstimateText
        summary = snapshot.summary
        tags = snapshot.tags
        latitude = snapshot.latitude
        longitude = snapshot.longitude

        var media: [String] = []
        if let cover = snapshot.localCoverName {
            media.append(cover)
        }
        for name in snapshot.galleryPhotoNames where !media.contains(name) {
            media.append(name)
            if media.count >= Self.maxMediaCount { break }
        }
        mediaNames = media
        baselineMediaNames = media
        Task { await hydrateMediaPreviews() }
    }

    private func hydrateMediaPreviews() async {
        for name in mediaNames {
            guard mediaPreviews[name] == nil else { continue }
            if let image = await Self.previewImage(named: name) {
                mediaPreviews[name] = image
            }
        }
    }

    private static func previewImage(named name: String) async -> UIImage? {
        guard let url = LocalMediaLibrary.fileURL(named: name) else { return nil }
        if LocalMediaLibrary.isVideo(url: url) {
            return await LocalMediaLibrary.posterImage(for: url)
        }
        return await PlatformLocalImageCache.loadAsync(atPath: url.path)
    }

    private static func displayAmount(from fee: String) -> String {
        let trimmed = fee.trimmingCharacters(in: .whitespacesAndNewlines)
        var digits = ""
        var started = false
        for character in trimmed {
            if character.isNumber {
                digits.append(character)
                started = true
            } else if character == ".", started, !digits.contains(".") {
                digits.append(character)
            } else if started {
                break
            }
        }
        if !digits.isEmpty { return digits }
        return trimmed
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: "/人", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func displayAAEstimate(from fee: String) -> String {
        let trimmed = fee.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: "约") {
            return String(trimmed[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}
