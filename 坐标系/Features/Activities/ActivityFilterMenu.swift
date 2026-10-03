//
//  ActivityFilterMenu.swift
//  坐标系
//
//  活动筛选：顶栏系统 Menu + inline Picker / Toggle，选完即时生效。
//  距离半径仅写入浏览会话状态，不改全局 RecommendationConfig。
//

import SwiftUI
import CoordinateModels

// MARK: - Modes

private enum ActivityFilterDateMode: String, CaseIterable, Identifiable {
    case any
    case today
    case tomorrow
    case weekend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any: ActivityFilterCopy.whenAny
        case .today: ActivityFilterCopy.whenToday
        case .tomorrow: ActivityFilterCopy.whenTomorrow
        case .weekend: ActivityFilterCopy.whenWeekend
        }
    }

    var quickFilter: ActivityQuickFilter? {
        switch self {
        case .any: nil
        case .today: .today
        case .tomorrow: .tomorrow
        case .weekend: .weekend
        }
    }

    init(quickFilters: Set<ActivityQuickFilter>) {
        if quickFilters.contains(.today) {
            self = .today
        } else if quickFilters.contains(.tomorrow) {
            self = .tomorrow
        } else if quickFilters.contains(.weekend) {
            self = .weekend
        } else {
            self = .any
        }
    }
}

/// 距离档位：`rawValue == 0` 表示不限。
private enum ActivityFilterDistancePreset: Int, CaseIterable, Identifiable {
    case any = 0
    case three = 3
    case five = 5
    case ten = 10
    case twentyFive = 25

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .any: ActivityFilterCopy.distanceAny
        case .three: ActivityFilterCopy.distanceThree
        case .five: ActivityFilterCopy.distanceFive
        case .ten: ActivityFilterCopy.distanceTen
        case .twentyFive: ActivityFilterCopy.distanceTwentyFive
        }
    }

    var kilometers: Double? {
        self == .any ? nil : Double(rawValue)
    }

    init(kilometers: Double?) {
        guard let kilometers, kilometers > 0 else {
            self = .any
            return
        }
        let rounded = Int(kilometers.rounded())
        if let exact = Self(rawValue: rounded), exact != .any {
            self = exact
            return
        }
        if rounded <= 4 { self = .three }
        else if rounded <= 7 { self = .five }
        else if rounded <= 15 { self = .ten }
        else { self = .twentyFive }
    }
}

// MARK: - Menu

/// 顶栏筛选 Menu 内容：时间 / 距离 / 费用名额，变更立即写入绑定。
struct ActivityFilterMenuContent: View {
    @Binding var quickFilters: Set<ActivityQuickFilter>
    /// 浏览会话「附近」半径（km）；与 `.nearby` 同进同出，不写全局偏好。
    @Binding var nearbyRadiusKM: Double?

    private var hasActiveFilters: Bool {
        !quickFilters.isEmpty
    }

    private var dateMode: Binding<ActivityFilterDateMode> {
        Binding(
            get: { ActivityFilterDateMode(quickFilters: quickFilters) },
            set: { mode in
                var next = quickFilters.filter { !$0.isTimeFilter }
                if let filter = mode.quickFilter {
                    next.insert(filter)
                }
                quickFilters = next
            }
        )
    }

    private var distancePreset: Binding<ActivityFilterDistancePreset> {
        Binding(
            get: {
                guard quickFilters.contains(.nearby) else { return .any }
                return ActivityFilterDistancePreset(kilometers: nearbyRadiusKM)
            },
            set: { preset in
                var next = quickFilters
                if let kilometers = preset.kilometers {
                    nearbyRadiusKM = kilometers
                    next.insert(.nearby)
                } else {
                    nearbyRadiusKM = nil
                    next.remove(.nearby)
                }
                quickFilters = next
            }
        )
    }

    private var freeOnly: Binding<Bool> {
        toggleBinding(for: .free)
    }

    private var availableOnly: Binding<Bool> {
        toggleBinding(for: .available)
    }

    var body: some View {
        Section(ActivityFilterCopy.whenSection) {
            Picker(ActivityFilterCopy.whenSection, selection: dateMode) {
                ForEach(ActivityFilterDateMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }

        Section(ActivityFilterCopy.distanceSection) {
            Picker(ActivityFilterCopy.distanceSection, selection: distancePreset) {
                ForEach(ActivityFilterDistancePreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }

        Section {
            Toggle(ActivityFilterCopy.free, systemImage: ActivityQuickFilter.free.systemImage, isOn: freeOnly)
            Toggle(
                ActivityFilterCopy.available,
                systemImage: ActivityQuickFilter.available.systemImage,
                isOn: availableOnly
            )
        }

        if hasActiveFilters {
            Button(ActivityFilterCopy.clear, systemImage: "xmark.circle", role: .destructive) {
                quickFilters = []
                nearbyRadiusKM = nil
            }
        }
    }

    private func toggleBinding(for filter: ActivityQuickFilter) -> Binding<Bool> {
        Binding(
            get: { quickFilters.contains(filter) },
            set: { isOn in
                var next = quickFilters
                if isOn {
                    next.insert(filter)
                } else {
                    next.remove(filter)
                }
                quickFilters = next
            }
        )
    }
}
