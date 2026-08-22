//
//  BuddyBookingSheet.swift
//  坐标系
//
//  陪玩下单：单 Sheet 选档期 → 确认（系统 DatePicker / Picker，避免 Form 内嵌自定义 Grid 卡死）。
//

import SwiftUI

private enum BuddyBookingStep: Hashable {
    case select
    case confirm
}

struct BuddyBookingSheet: View {
    let presentation: BuddyBookingPresentation
    var onBooked: (_ scheduledAt: Date, _ hours: Int, _ slotLabel: String?) -> Void
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(AppModel.self) private var app

    @State private var step: BuddyBookingStep = .select
    @State private var selectedDay = Date()
    @State private var selectedSlot: String?
    @State private var useCustomTime = false
    @State private var scheduledAt = Date.now.addingTimeInterval(60 * 60 * 24)
    @State private var hours = 2
    @State private var showCreateAccount = false
    @State private var didBootstrap = false

    private var companion: PaidCompanion { presentation.companion }
    private let chineseLocale = Locale(identifier: "zh_CN")

    private var resolvedSlots: [BuddyScheduleSlot.Resolved] {
        BuddyScheduleSlot.resolveAll(companion.scheduleSlots)
    }

    private var slotsOnSelectedDay: [BuddyScheduleSlot.Resolved] {
        BuddyScheduleSlot.slots(on: selectedDay, from: companion.scheduleSlots)
    }

    private var bookableSlotsOnDay: [BuddyScheduleSlot.Resolved] {
        slotsOnSelectedDay.filter(\.bookable)
    }

    private var totalPrice: Int {
        companion.hourlyPrice * hours
    }

    private var priceSummaryText: String {
        if let sku = presentation.serviceSKU {
            return sku.priceText
        }
        return companion.priceText
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

    private var canProceed: Bool {
        guard companion.isAvailable else { return false }
        if useCustomTime { return true }
        if companion.scheduleSlots.isEmpty { return true }
        return selectedSlot != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .select:
                    selectContent
                case .confirm:
                    confirmContent
                }
            }
            .navigationTitle(
                step == .select
                    ? BuddyBookingFlowCopy.selectStepTitle
                    : BuddyBookingFlowCopy.confirmStepTitle
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { bookingToolbar }
            .onAppear(perform: bootstrapIfNeeded)
            .onChange(of: selectedDay) { _, _ in
                syncSlotForSelectedDay()
            }
            .onChange(of: useCustomTime) { _, custom in
                if custom {
                    selectedSlot = nil
                } else {
                    syncSlotForSelectedDay()
                }
            }
        }
        .environment(\.locale, chineseLocale)
        .platformSheet(.form)
        .sheet(isPresented: $showCreateAccount) {
            ProfileCreateAccountSheet(
                session: app.auth,
                reason: GuestAccessGate.commerceReason
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    @ToolbarContentBuilder
    private var bookingToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if step == .confirm {
                Button(BuddyBookingFlowCopy.back) {
                    step = .select
                }
            } else {
                Button(BuddyBookingFlowCopy.cancel) {
                    onDismiss()
                    dismiss()
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            if step == .select {
                Button(BuddyBookingFlowCopy.nextStep) {
                    guard canProceed else { return }
                    step = .confirm
                }
                .fontWeight(.semibold)
                .disabled(!canProceed)
            } else {
                Button(BuddyBookingFlowCopy.submitBooking) {
                    submitBooking()
                }
                .fontWeight(.semibold)
                .disabled(!canProceed)
            }
        }
    }

    @ViewBuilder
    private var selectContent: some View {
        if !companion.isAvailable {
            unavailableState
        } else {
            Form {
                headerSection

                if let sku = presentation.serviceSKU {
                    Section("已选服务") {
                        LabeledContent(sku.title, value: sku.priceText)
                        Text(sku.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !companion.scheduleSlots.isEmpty, !useCustomTime {
                    scheduleSections
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
            }
        }
    }

    @ViewBuilder
    private var confirmContent: some View {
        Form {
            Section {
                LabeledContent("陪玩", value: companion.profile.nickname)
                if let sku = presentation.serviceSKU {
                    LabeledContent("服务项目", value: sku.title)
                } else {
                    LabeledContent("服务项目", value: companion.serviceType.rawValue)
                }
                LabeledContent("开始时间") {
                    Text(
                        "\(Formatters.monthDay.string(from: resolvedStart)) "
                        + Formatters.shortTime.string(from: resolvedStart)
                    )
                }
                LabeledContent("时长", value: "\(hours) 小时")
                LabeledContent("计价", value: priceSummaryText)
                LabeledContent("费用合计", value: "¥\(totalPrice)")
                if let selectedSlot, !useCustomTime {
                    LabeledContent("档期", value: selectedSlot)
                }
            } header: {
                Text("预约信息")
            } footer: {
                Text("提交后等待陪玩确认；接单后完成支付即可锁定档期。")
            }
        }
    }

    private var unavailableState: some View {
        ContentUnavailableView {
            Label(BuddyBookingFlowCopy.unavailableTitle, systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text(BuddyBookingFlowCopy.unavailableBody)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
                HStack {
                    Text(companion.profile.nickname)
                        .font(.headline)
                    if companion.isVerified {
                        PlatformCaptionBadge(title: "认证", chrome: .tint(PlatformStatus.success))
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
    }

    @ViewBuilder
    private var scheduleSections: some View {
        Section {
            DatePicker(
                "预约日期",
                selection: $selectedDay,
                in: bookingDateRange,
                displayedComponents: [.date]
            )
        } header: {
            Text("可选档期")
        } footer: {
            Text("先选日期，再选当日可约时段。")
        }

        Section {
            if bookableSlotsOnDay.isEmpty {
                Text(emptyDayMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if bookableSlotsOnDay.count == 1, let only = bookableSlotsOnDay.first {
                LabeledContent("时段", value: only.label)
                    .accessibilityAddTraits(.isSelected)
            } else {
                Picker("时段", selection: slotSelection) {
                    ForEach(bookableSlotsOnDay) { slot in
                        Text(slot.label).tag(slot.label)
                    }
                }
                .pickerStyle(.inline)
            }
        } header: {
            Text(daySectionTitle)
        }
    }

    private var slotSelection: Binding<String> {
        Binding(
            get: { selectedSlot ?? bookableSlotsOnDay.first?.label ?? "" },
            set: { selectedSlot = $0.isEmpty ? nil : $0 }
        )
    }

    private var bookingDateRange: ClosedRange<Date> {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .month, value: 2, to: start) ?? start
        return start...end
    }

    private var daySectionTitle: String {
        selectedDay.formatted(
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

    private func bootstrapIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true

        if let initialDay = presentation.initialDay {
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
            selectedDay = calendar.startOfDay(for: Date())
            selectedSlot = nil
        }
    }

    private func syncSlotForSelectedDay() {
        guard !useCustomTime, !companion.scheduleSlots.isEmpty else { return }
        selectedDay = calendar.startOfDay(for: selectedDay)
        let bookable = bookableSlotsOnDay
        guard !bookable.isEmpty else {
            selectedSlot = nil
            return
        }
        if let selectedSlot,
           bookable.contains(where: { $0.label == selectedSlot }) {
            return
        }
        selectedSlot = bookable.first?.label
    }

    private func submitBooking() {
        guard GuestAccessGate.allow(app.auth, presentCreateAccount: $showCreateAccount) else { return }
        onBooked(
            resolvedStart,
            hours,
            useCustomTime ? nil : selectedSlot
        )
        onDismiss()
        dismiss()
    }
}
