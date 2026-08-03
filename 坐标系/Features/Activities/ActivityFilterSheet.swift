//
//  ActivityFilterSheet.swift
//  坐标系
//
//  活动筛选：日期用系统 Wheel DatePicker（年 / 月 / 日滚动轴）。
//

import SwiftUI

/// 把「日期 / 附近 / 免费 / 有空位」收进筛选面板，首屏只留一行分类
struct ActivityFilterSheet: View {
    @Binding var quickFilters: Set<ActivityQuickFilter>
    @Binding var dayFilter: Date?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar

    @State private var restrictsDate = false
    @State private var selectedDay = Date()
    @State private var nearby = false
    @State private var free = false
    @State private var available = false

    private var earliestDay: Date {
        calendar.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("指定日期", isOn: $restrictsDate)

                    if restrictsDate {
                        DatePicker(
                            "日期",
                            selection: $selectedDay,
                            in: earliestDay...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .environment(\.calendar, Calendar(identifier: .gregorian))
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("日期")
                        .accessibilityValue(dateAccessibilityValue)
                    }
                } header: {
                    Text("时间")
                } footer: {
                    Text(
                        restrictsDate
                            ? "滚动选择年、月、日，只看当天活动。"
                            : "不限日期，覆盖各工作日与时段。"
                    )
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
            .onChange(of: restrictsDate) { _, enabled in
                if enabled {
                    selectedDay = max(calendar.startOfDay(for: selectedDay), earliestDay)
                }
            }
        }
        .platformSheet(.filter)
    }

    private var dateAccessibilityValue: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return selectedDay.formatted(
            Date.FormatStyle(date: .complete, time: .omitted, locale: Locale(identifier: "zh_CN"), calendar: calendar)
        )
    }

    private func loadDraft() {
        nearby = quickFilters.contains(.nearby)
        free = quickFilters.contains(.free)
        available = quickFilters.contains(.available)

        if let dayFilter {
            restrictsDate = true
            selectedDay = calendar.startOfDay(for: dayFilter)
        } else if quickFilters.contains(.today) {
            restrictsDate = true
            selectedDay = earliestDay
        } else if quickFilters.contains(.tomorrow),
                  let tomorrow = calendar.date(byAdding: .day, value: 1, to: earliestDay) {
            restrictsDate = true
            selectedDay = tomorrow
        } else {
            restrictsDate = false
            selectedDay = earliestDay
        }
    }

    private func resetDraft() {
        restrictsDate = false
        selectedDay = earliestDay
        nearby = false
        free = false
        available = false
    }

    private func applyDraft() {
        var next: Set<ActivityQuickFilter> = []
        if nearby { next.insert(.nearby) }
        if free { next.insert(.free) }
        if available { next.insert(.available) }
        quickFilters = next
        dayFilter = restrictsDate ? calendar.startOfDay(for: selectedDay) : nil
    }
}
