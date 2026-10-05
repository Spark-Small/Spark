//
//  BuddyFilterSheet+Draft.swift
//  坐标系
//
//  深筛选 draft 同步（L1 Menu 已接管排序 / 性别 / 可约 / 服务类型 / 俱乐部主题）。
//

import SwiftUI
import CoordinateModels

extension BuddyFilterSheet {
    // MARK: - Draft

    func loadDraft() {
        draftMaxDistanceKM = min(
            max(filter.maxDistanceKM, BuddyFilterDistance.minimumKilometers),
            BuddyFilterDistance.maximumKilometers
        )
        draftHobby = filter.hobby
        draftIntents = filter.intents
        draftUsesSystemLocation = usesSystemLocation
        draftSelectedCityID = selectedCityID
    }

    func resetDraft() {
        draftMaxDistanceKM = BuddyFilterDistance.maximumKilometers
        draftHobby = nil
        draftIntents = []
        draftUsesSystemLocation = true
        draftSelectedCityID = BuddyCityCatalog.default.id
        path = NavigationPath()
    }

    func applyDraft() {
        switch filter.kind {
        case .free:
            filter.maxDistanceKM = draftMaxDistanceKM
            filter.hobby = draftHobby
            filter.intents = draftIntents
        case .paid:
            filter.maxDistanceKM = draftMaxDistanceKM
        case .clubs:
            break
        }
        usesSystemLocation = draftUsesSystemLocation
        selectedCityID = draftSelectedCityID
        if draftUsesSystemLocation {
            onUseSystemLocation()
        }
    }

    var locationSubtitle: String {
        if let locatedPlaceName, !locatedPlaceName.isEmpty {
            return locatedPlaceName
        }
        if needsLocationPermission {
            return "未开启定位"
        }
        return "正在获取…"
    }

    var distanceValueTitle: String {
        if draftMaxDistanceKM >= BuddyFilterDistance.maximumKilometers {
            return "不限距离"
        }
        if draftMaxDistanceKM <= 3 {
            return "附近"
        }
        if draftMaxDistanceKM <= 8 {
            return "片区"
        }
        if draftMaxDistanceKM <= 15 {
            return "同城"
        }
        return "较远"
    }

    var distanceValueCaption: String {
        if draftMaxDistanceKM >= BuddyFilterDistance.maximumKilometers {
            return "\(Int(BuddyFilterDistance.maximumKilometers))+ km"
        }
        return "\(Int(draftMaxDistanceKM)) km"
    }
}
