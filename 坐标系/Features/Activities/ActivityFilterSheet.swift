//
//  ActivityFilterSheet.swift
//  坐标系
//

import SwiftUI

/// 把「今天 / 明天 / 附近 / 免费 / 有空位」收进筛选面板，首屏只留一行分类
struct ActivityFilterSheet: View {
    @Binding var quickFilters: Set<ActivityQuickFilter>
    @Environment(\.dismiss) private var dismiss

    @State private var timeFilter: TimeOption = .any
    @State private var nearby = false
    @State private var free = false
    @State private var available = false

    private enum TimeOption: String, CaseIterable, Identifiable {
        case any = "不限"
        case today = "今天"
        case tomorrow = "明天"

        var id: String { rawValue }

        var quickFilter: ActivityQuickFilter? {
            switch self {
            case .any: nil
            case .today: .today
            case .tomorrow: .tomorrow
            }
        }

        init(from filters: Set<ActivityQuickFilter>) {
            if filters.contains(.today) {
                self = .today
            } else if filters.contains(.tomorrow) {
                self = .tomorrow
            } else {
                self = .any
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("时间", selection: $timeFilter) {
                        ForEach(TimeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("时间")
                } footer: {
                    Text("覆盖午间、晚间与各工作日，不限周末")
                }

                Section("条件") {
                    Toggle(isOn: $nearby) {
                        Label("附近", systemImage: "location")
                            .platformContentSymbolStyle()
                    }
                    Toggle(isOn: $free) {
                        Label("免费", systemImage: "gift")
                            .platformContentSymbolStyle()
                    }
                    Toggle(isOn: $available) {
                        Label("有空位", systemImage: "person.badge.plus")
                            .platformContentSymbolStyle()
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("重置") { resetDraft() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        applyDraft()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { loadDraft() }
        }
        .platformSheet(.filter)
    }

    private func loadDraft() {
        timeFilter = TimeOption(from: quickFilters)
        nearby = quickFilters.contains(.nearby)
        free = quickFilters.contains(.free)
        available = quickFilters.contains(.available)
    }

    private func resetDraft() {
        timeFilter = .any
        nearby = false
        free = false
        available = false
    }

    private func applyDraft() {
        var next: Set<ActivityQuickFilter> = []
        if let time = timeFilter.quickFilter {
            next.insert(time)
        }
        if nearby { next.insert(.nearby) }
        if free { next.insert(.free) }
        if available { next.insert(.available) }
        quickFilters = next
    }
}
