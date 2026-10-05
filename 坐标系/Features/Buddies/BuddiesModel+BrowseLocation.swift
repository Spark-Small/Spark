//
//  BuddiesModel+BrowseLocation.swift
//  坐标系
//
//  搭子发现：定位匹配、城市选择、筛选 Toolbar 摘要。
//  软启动：系统定位只服务天气 / 展示文案，不硬杀样例或远程货架；
//  用户手动选城后才按 `selectedCity` 过滤（与空态文案同源）。
//

import CoordinateModels
import Foundation

extension BuddiesModel {
    var selectedCity: BuddyCityChoice {
        BuddyCityCatalog.city(id: selectedCityID) ?? BuddyCityCatalog.default
    }

    var hasActiveBrowseFilters: Bool {
        // 默认城 + 关系统定位 = 软启动常态，不算「筛选生效」
        if !filter.isDefault { return true }
        if !usesSystemLocation, selectedCityID != BuddyCityCatalog.default.id {
            return true
        }
        return false
    }

    /// 顶栏筛选按钮：未生效 = 漏斗；生效 = 当前主条件图标（多条件取优先项，无角标）。
    var browseFilterToolbarSystemImage: String {
        guard hasActiveBrowseFilters else {
            return "line.3.horizontal.decrease"
        }
        switch filter.kind {
        case .clubs:
            if let topic = filter.clubTopic,
               let option = ClubTopicOption(rawValue: topic) {
                return option.systemImage
            }
            if !usesSystemLocation {
                return "building.2"
            }
        case .paid:
            if filter.availableOnly {
                return "calendar.badge.clock"
            }
            if let serviceType = filter.serviceType {
                return serviceType.systemImage
            }
            if filter.gender != nil {
                return "person"
            }
            if filter.maxDistanceKM < BuddyFilterDistance.maximumKilometers {
                return "location"
            }
            if !usesSystemLocation {
                return "building.2"
            }
        case .free:
            if filter.gender != nil {
                return "person"
            }
            if !filter.intents.isEmpty {
                return "sparkles"
            }
            if let hobby = filter.hobby, !hobby.isEmpty {
                return BuddyHobbyOption.systemImage(for: hobby)
            }
            if filter.maxDistanceKM < BuddyFilterDistance.maximumKilometers {
                return "location"
            }
            if !usesSystemLocation {
                return "building.2"
            }
        }
        return "line.3.horizontal.decrease.circle.fill"
    }

    var browseRegionAccessibilityLabel: String {
        if usesSystemLocation {
            if let locatedPlaceName, !locatedPlaceName.isEmpty {
                return BuddyBrowseCopy.ModelCopy.locatedAt(locatedPlaceName)
            }
            return BuddyBrowseCopy.ModelCopy.locating
        }
        return selectedCity.menuTitle
    }

    /// 筛选 Toolbar / a11y：按模式摘要生效条件
    var browseFilterAccessibilitySummary: String {
        var parts: [String] = []
        if usesSystemLocation {
            if let locatedPlaceName, !locatedPlaceName.isEmpty {
                parts.append(locatedPlaceName)
            } else {
                parts.append(BuddyBrowseCopy.ModelCopy.locating)
            }
        } else {
            parts.append(selectedCity.menuTitle)
        }

        switch filter.kind {
        case .free:
            if filter.maxDistanceKM < BuddyFilterDistance.maximumKilometers {
                parts.append("\(Int(filter.maxDistanceKM)) km")
            }
            if let gender = filter.gender {
                parts.append(gender == .female ? BuddyFilterCopy.genderFemale : BuddyFilterCopy.genderMale)
            }
            if let hobby = filter.hobby, !hobby.isEmpty {
                parts.append(hobby)
            }
            if !filter.intents.isEmpty {
                parts.append(filter.intents.map(\.rawValue).sorted().joined(separator: "·"))
            }
        case .paid:
            if filter.maxDistanceKM < BuddyFilterDistance.maximumKilometers {
                parts.append("\(Int(filter.maxDistanceKM)) km")
            }
            if filter.availableOnly {
                parts.append(BuddyBrowseCopy.availableOnlyChip)
            }
            if let serviceType = filter.serviceType {
                parts.append(serviceType.rawValue)
            }
            if let gender = filter.gender {
                parts.append(gender == .female ? BuddyFilterCopy.genderFemale : BuddyFilterCopy.genderMale)
            }
        case .clubs:
            if let topic = filter.clubTopic, !topic.isEmpty {
                parts.append(topic)
            }
        }

        return parts.joined(separator: " · ")
    }

    /// 俱乐部货架：主题 + 城市 + 排序。
    func filteredCircles(sortedBy sort: BuddyClubSort) -> [InterestCircle] {
        var circles = allCircles.filter { circle in
            if let topic = filter.clubTopic, !topic.isEmpty {
                let hit = circle.topic == topic
                    || circle.tags.contains(where: { $0.caseInsensitiveCompare(topic) == .orderedSame })
                if !hit { return false }
            }
            return matchesBrowseLocation(circle.city)
        }

        switch sort {
        case .active:
            circles.sort {
                if $0.weeklyActive != $1.weeklyActive {
                    return $0.weeklyActive > $1.weeklyActive
                }
                return $0.memberCount > $1.memberCount
            }
        case .members:
            circles.sort {
                if $0.memberCount != $1.memberCount {
                    return $0.memberCount > $1.memberCount
                }
                return $0.weeklyActive > $1.weeklyActive
            }
        case .newest:
            circles.sort { $0.createdAt > $1.createdAt }
        }
        return circles
    }

    /// 发现列表城市匹配。
    /// - 样例目录软启动：系统定位**不**参与硬过滤（实机 GPS 常落在样例外城市 → 整页空）。
    /// - 用户手动选城：按所选城过滤。
    func matchesBrowseLocation(_ locationText: String) -> Bool {
        if sampleCatalogEnabled, usesSystemLocation {
            return true
        }
        if usesSystemLocation {
            // 远程目录尚未接地理查询前，系统定位同样不硬杀列表
            return true
        }
        return selectedCity.matches(locationText: locationText)
    }

    func syncLocatedPlaceName(_ placeName: String?) {
        locatedPlaceName = placeName
        // 软启动：定位文案只更新展示，不改写 selectedCityID，避免筛选项被 GPS 带跑
    }

    func useSystemLocationMode() {
        usesSystemLocation = true
    }

    func selectManualCity(id: String) {
        usesSystemLocation = false
        selectedCityID = id
    }
}
