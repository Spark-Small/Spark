//
//  BuddyBookingSheet.swift
//  坐标系
//

import SwiftUI

struct BuddyBookingSheet: View {
    let companion: PaidCompanion
    /// 打开时预选的自然日（详情页点日历日期可传入）
    var initialDay: Date? = nil
    var onBooked: (_ scheduledAt: Date, _ hours: Int, _ slotLabel: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar

    @State private var selectedDay: Date?
    @State private var selectedSlot: String?
    @State private var useCustomTime = false
    @State private var scheduledAt = Date.now.addingTimeInterval(60 * 60 * 24)
    @State private var hours = 2

    private var resolvedSlots: [BuddyScheduleSlot.Resolved] {
        BuddyScheduleSlot.resolveAll(companion.scheduleSlots)
    }

    private var slotsOnSelectedDay: [BuddyScheduleSlot.Resolved] {
        guard let selectedDay else { return [] }
        return BuddyScheduleSlot.slots(on: selectedDay, from: companion.scheduleSlots)
    }

    private var bookableSlotsOnDay: [BuddyScheduleSlot.Resolved] {
        slotsOnSelectedDay.filter(\.bookable)
    }

    private var totalPrice: Int {
        companion.hourlyPrice * hours
    }

    private var resolvedStart: Date {
        if useCustomTime {
            return scheduledAt
        }
        if let selectedSlot {
            return BuddyScheduleSlot.resolveDate(from: selectedSlot)
        }
        return scheduledAt
    }

    private var canSubmit: Bool {
        guard companion.isAvailable else { return false }
        if useCustomTime { return true }
        return selectedSlot != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
                        HStack {
                            Text(companion.profile.nickname)
                                .font(.headline)
                            if companion.isVerified {
                                Text("认证")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(PlatformStatus.success.opacity(0.15), in: Capsule())
                                    .foregroundStyle(PlatformStatus.success)
                            }
                        }
                        Text(companion.specialty)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(companion.priceText) · \(companion.responseTime) 回复")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                }

                if !companion.scheduleSlots.isEmpty, !useCustomTime {
                    Section {
                        BuddyScheduleCalendarView(
                            slots: companion.scheduleSlots,
                            selectedDay: $selectedDay
                        )
                        .listRowInsets(
                            EdgeInsets(
                                top: PlatformMetrics.formRowVerticalPadding,
                                leading: PlatformMetrics.contentInset,
                                bottom: PlatformMetrics.formRowVerticalPadding,
                                trailing: PlatformMetrics.contentInset
                            )
                        )
                    } header: {
                        Text("可选档期")
                    } footer: {
                        Text("日期下方「可约」表示有空档；点选日期后选择具体时段，无需先私信。")
                    }

                    if selectedDay != nil {
                        Section {
                            if bookableSlotsOnDay.isEmpty {
                                Text(emptyDayMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(bookableSlotsOnDay) { slot in
                                    Button {
                                        selectedSlot = slot.label
                                    } label: {
                                        HStack {
                                            Label(slot.label, systemImage: "clock")
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            if selectedSlot == slot.label {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.tint)
                                            }
                                        }
                                    }
                                    .accessibilityAddTraits(selectedSlot == slot.label ? .isSelected : [])
                                }
                            }
                        } header: {
                            Text(daySectionTitle)
                        }
                    }
                }

                Section {
                    Toggle("自定义时间", isOn: $useCustomTime)
                    if useCustomTime {
                        DatePicker(
                            "开始时间",
                            selection: $scheduledAt,
                            in: Date.now...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                    Stepper(value: $hours, in: 1...8) {
                        LabeledContent("时长", value: "\(hours) 小时")
                    }
                } header: {
                    Text(useCustomTime || companion.scheduleSlots.isEmpty ? "预约时间" : "时长")
                } footer: {
                    if companion.scheduleSlots.isEmpty {
                        Text("对方暂未公开档期，可自选开始时间提交，等待确认。")
                    }
                }

                Section("确认信息") {
                    LabeledContent("服务类型", value: companion.serviceType.rawValue)
                    LabeledContent("费用合计", value: "¥\(totalPrice)")
                    LabeledContent("档期状态", value: companion.isAvailable ? "可预约" : "暂不可约")
                    if let selectedSlot, !useCustomTime {
                        LabeledContent("已选档期", value: selectedSlot)
                    }
                }
            }
            .navigationTitle("预约陪玩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("提交预约") {
                        onBooked(
                            resolvedStart,
                            hours,
                            useCustomTime ? nil : selectedSlot
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSubmit)
                }
            }
            .onAppear {
                bootstrapSelection()
            }
            .onChange(of: selectedDay) { _, day in
                guard !useCustomTime, let day else {
                    selectedSlot = nil
                    return
                }
                let bookable = BuddyScheduleSlot.slots(on: day, from: companion.scheduleSlots)
                    .filter(\.bookable)
                if let selectedSlot,
                   bookable.contains(where: { $0.label == selectedSlot }) {
                    return
                }
                selectedSlot = bookable.first?.label
            }
            .onChange(of: useCustomTime) { _, custom in
                if custom {
                    selectedSlot = nil
                } else if selectedDay == nil {
                    bootstrapSelection()
                } else if let selectedDay {
                    selectedSlot = BuddyScheduleSlot.slots(on: selectedDay, from: companion.scheduleSlots)
                        .first(where: \.bookable)?
                        .label
                }
            }
        }
        .platformSheet(.browser)
    }

    private var daySectionTitle: String {
        guard let selectedDay else { return "当日时段" }
        return selectedDay.formatted(
            Date.FormatStyle()
                .month()
                .day()
                .weekday(.wide)
                .locale(Locale(identifier: "zh_CN"))
        )
    }

    private var emptyDayMessage: String {
        let status = slotsOnSelectedDay.first?.availability
        switch status {
        case .full: return "当天档期已满，请换一天。"
        case .pending: return "当天档期待开放，请稍后再约或换一天。"
        default: return "当天暂无可约时段。"
        }
    }

    private func bootstrapSelection() {
        if let initialDay {
            let day = calendar.startOfDay(for: initialDay)
            let bookable = BuddyScheduleSlot.slots(on: day, from: companion.scheduleSlots)
                .filter(\.bookable)
            if !bookable.isEmpty {
                selectedDay = day
                selectedSlot = bookable.first?.label
                return
            }
        }

        if let first = resolvedSlots.first(where: \.bookable) {
            selectedDay = first.dayStart(calendar: calendar)
            selectedSlot = first.label
        } else {
            selectedDay = nil
            selectedSlot = nil
        }
    }
}
