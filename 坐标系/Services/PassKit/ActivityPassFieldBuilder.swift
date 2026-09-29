//
//  ActivityPassFieldBuilder.swift
//  坐标系
//
//  活动行程票面字段：严格对齐 PassKit eventTicket 槽位，每类信息只出现一次。
//
//  headerFields · primaryFields · secondaryFields · auxiliaryFields（≤4）
//  时间 → header；活动名 → primary；地点 → secondary；座位/费用/人数/主理 → auxiliary
//

import Foundation
import CoordinateModels

/// 票种语义（活动标题区角标；彩绘见 CredentialArtCatalog）。
enum ActivityJourneyPassKind: String, CaseIterable, Identifiable {
    case transit
    case event
    case dining
    case workshop
    case generic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .transit: "出行票"
        case .event: "活动票"
        case .dining: "订位票"
        case .workshop: "体验票"
        case .generic: "行程票"
        }
    }

    static func forCategory(_ category: ActivityCategory) -> ActivityJourneyPassKind {
        switch category {
        case .outdoorSports, .cityExplore:
            return .transit
        case .entertainment, .interestSocial:
            return .event
        case .food:
            return .dining
        case .handmade, .learning:
            return .workshop
        case .all, .forYou:
            return .generic
        }
    }
}

enum ActivityPassCopy {
    static let activity = "活动"
    static let location = "地点"
    static let seat = "座位号"
    static let fee = "费用"
    static let partySize = "人数"
    static let reservation = "订位号"
    static let organizer = "主理"
    static let pendingPlace = "待定"
}

private enum ActivityJourneyPassPlaceLimits {
    static let district = 8
    static let spot = 14
}

/// 票面地点解析（完整地址仅在 pass backFields）。
struct ActivityJourneyPassPlace: Hashable {
    let district: String
    let spot: String
    let full: String

    var showsSpotLine: Bool {
        spot != district
    }
}

enum ActivityPassFieldBuilder {
    static func kind(for category: ActivityCategory) -> ActivityJourneyPassKind {
        ActivityJourneyPassKind.forCategory(category)
    }

    static func place(for activity: Activity) -> ActivityJourneyPassPlace {
        let raw = activity.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = raw.isEmpty ? activity.title : raw
        let segments = full
            .split(separator: "·", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let districtSource = segments.first ?? full
        let spotSource: String
        if segments.count >= 2 {
            spotSource = segments.dropFirst().joined(separator: "·")
        } else {
            spotSource = districtSource
        }

        return ActivityJourneyPassPlace(
            district: compactLabel(districtSource, maxLength: ActivityJourneyPassPlaceLimits.district),
            spot: compactLabel(spotSource, maxLength: ActivityJourneyPassPlaceLimits.spot),
            full: full
        )
    }

    /// secondaryFields：集合点 / 场馆（不含已在 header 出现的时间）。
    static func locationValue(for activity: Activity) -> String {
        let place = place(for: activity)
        if place.showsSpotLine { return place.spot }
        return place.district.isEmpty ? ActivityPassCopy.pendingPlace : place.district
    }

    /// auxiliaryFields：仅履约决策字段，不重复 primary / secondary / header。
    static func auxiliaryFields(
        for activity: Activity,
        feeLine: String,
        journey: ActivityPassJourneyContext?
    ) -> [PassField] {
        let seat = journey.map {
            ActivityJourneyPresentation.seatNumber(activityID: activity.id, userID: $0.userID)
        }
        let isDining = kind(for: activity.category) == .dining
        let partySize = "\(max(activity.joined, 1))/\(max(activity.capacity, max(activity.joined, 1)))"

        var fields: [PassField] = []

        if let seat {
            if isDining {
                fields.append(PassField(key: "reservation", label: ActivityPassCopy.reservation, value: seat))
            } else {
                fields.append(PassField(key: "seat", label: ActivityPassCopy.seat, value: seat))
            }
        }

        fields.append(PassField(key: "fee", label: ActivityPassCopy.fee, value: feeLine))

        if isDining {
            fields.append(PassField(key: "partySize", label: ActivityPassCopy.partySize, value: partySize))
        } else {
            fields.append(
                PassField(
                    key: "attendance",
                    label: ActivityPassCopy.partySize,
                    value: WalletPassFaceFactory.attendanceHint(for: activity)
                )
            )
        }

        if fields.count < 4, !activity.hostName.isEmpty {
            fields.append(
                PassField(key: "organizer", label: ActivityPassCopy.organizer, value: activity.hostName)
            )
        }

        return Array(fields.prefix(4))
    }

    private static func compactLabel(_ text: String, maxLength: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ActivityPassCopy.pendingPlace }
        guard trimmed.count > maxLength else { return trimmed }
        return String(trimmed.prefix(maxLength - 1)) + "…"
    }
}
