//
//  ActivityComposeDraft+Persistence.swift
//  坐标系
//
//  发起活动草稿：预填、本地快照与费用展示解析。
//

import Foundation
import CoordinateModels

extension ActivityComposeDraft {
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

    func apply(snapshot: ActivityComposeDraftSnapshot) {
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

    static func displayAmount(from fee: String) -> String {
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

    static func displayAAEstimate(from fee: String) -> String {
        let trimmed = fee.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: "约") {
            return String(trimmed[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}
