//
//  BuddyBookingSheet.swift
//  坐标系
//
//  陪玩下单：单 Sheet 选档期 → 确认（系统 DatePicker / Picker，避免 Form 内嵌自定义 Grid 卡死）。
//

import SwiftUI
import CoordinateModels

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

    @State private var step: BuddyBookingStep = .select
    @State private var selectedDay = Date()
    @State private var selectedSlot: String?
    @State private var useCustomTime = false
    @State private var scheduledAt = Date.now.addingTimeInterval(60 * 60 * 24)
    @State private var hours = 2
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
                .accessibilityHint(BuddyBookingFlowCopy.submitBookingAccessibilityHint)
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
                    Section(BuddyBookingFlowCopy.selectedServiceSection) {
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
                    Toggle(BuddyBookingFlowCopy.customTimeToggle, isOn: $useCustomTime)
                    if useCustomTime {
                        DatePicker(
                            BuddyBookingFlowCopy.startTime,
                            selection: $scheduledAt,
                            in: Date.now...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                    Stepper(value: $hours, in: 1...8) {
                        LabeledContent(BuddyBookingFlowCopy.duration, value: BuddyBookingFlowCopy.durationHours(hours))
                    }
                } header: {
                    Text(useCustomTime || companion.scheduleSlots.isEmpty ? BuddyBookingFlowCopy.bookingTimeSection : BuddyBookingFlowCopy.duration)
                } footer: {
                    if companion.scheduleSlots.isEmpty {
                        Text(BuddyBookingFlowCopy.scheduleEmptyHint)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var confirmContent: some View {
        Form {
            Section {
                LabeledContent(BuddyBookingFlowCopy.companionLabel, value: companion.profile.nickname)
                if let sku = presentation.serviceSKU {
                    LabeledContent(BuddyBookingFlowCopy.serviceItemLabel, value: sku.title)
                } else {
                    LabeledContent(BuddyBookingFlowCopy.serviceItemLabel, value: companion.serviceType.rawValue)
                }
                LabeledContent(BuddyBookingFlowCopy.startTime) {
                    Text(
                        "\(Formatters.monthDay.string(from: resolvedStart)) "
                        + Formatters.shortTime.string(from: resolvedStart)
                    )
                }
                LabeledContent(BuddyBookingFlowCopy.duration, value: BuddyBookingFlowCopy.durationHours(hours))
                LabeledContent(BuddyBookingFlowCopy.pricingLabel, value: priceSummaryText)
                LabeledContent(BuddyBookingFlowCopy.totalFeeLabel, value: "¥\(totalPrice)")
                if let selectedSlot, !useCustomTime {
                    LabeledContent(BuddyBookingFlowCopy.slotLabel, value: selectedSlot)
                }
            } header: {
                Text(BuddyBookingFlowCopy.bookingInfoSection)
            } footer: {
                Text(BuddyBookingFlowCopy.confirmFooter)
            }
        }
    }

    private var unavailableState: some View {
        ContentUnavailableView {
            Label(BuddyBookingFlowCopy.unavailableTitle, systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text(BuddyBookingFlowCopy.unavailableBody)
        } actions: {
            Button(BuddyBookingFlowCopy.unavailableDismiss) {
                onDismiss()
                dismiss()
            }
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
                        PlatformCaptionBadge(title: BuddyBookingFlowCopy.verifiedShort, chrome: .tint(PlatformStatus.success))
                    }
                }
                Text(companion.specialty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(BuddyBookingFlowCopy.priceReplyCaption(priceText: companion.priceText, responseTime: companion.responseTime))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
        }
    }

    @ViewBuilder
    private var scheduleSections: some View {
        Section {
            BuddyScheduleCalendarView(
                slots: companion.scheduleSlots,
                selectedDay: selectedDayBinding,
                allowsSelection: true,
                showsMonthPager: true
            )
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
        } header: {
            Text(BuddyBookingFlowCopy.availableSlotsHeader)
        } footer: {
            Text(BuddyBookingFlowCopy.availableSlotsFooter)
        }

        Section {
            if bookableSlotsOnDay.isEmpty {
                Text(emptyDayMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if bookableSlotsOnDay.count == 1, let only = bookableSlotsOnDay.first {
                LabeledContent(BuddyBookingFlowCopy.timeSlotLabel, value: only.label)
                    .accessibilityAddTraits(.isSelected)
            } else {
                Picker(BuddyBookingFlowCopy.timeSlotLabel, selection: slotSelection) {
                    ForEach(bookableSlotsOnDay) { slot in
                        Text(slot.label).tag(Optional(slot.label))
                    }
                }
                .pickerStyle(.inline)
            }
        } header: {
            Text(daySectionTitle)
        }
    }

    private var selectedDayBinding: Binding<Date?> {
        Binding(
            get: { calendar.startOfDay(for: selectedDay) },
            set: { day in
                guard let day else { return }
                selectedDay = calendar.startOfDay(for: day)
            }
        )
    }

    private var slotSelection: Binding<String?> {
        Binding(
            get: { selectedSlot },
            set: { selectedSlot = $0 }
        )
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
        let day = calendar.startOfDay(for: selectedDay)
        let status = BuddyScheduleSlot.dayAvailabilityMap(
            slots: companion.scheduleSlots,
            calendar: calendar
        )[day]
        switch status {
        case .full: return BuddyBookingFlowCopy.emptyDayFull
        case .pending: return BuddyBookingFlowCopy.emptyDayPending
        default: return BuddyBookingFlowCopy.emptyDayDefault
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
                useCustomTime = false
                return
            }
        }

        if let firstDay = BuddyScheduleSlot.firstBookableDay(
            slots: companion.scheduleSlots,
            calendar: calendar
        ) {
            selectedDay = firstDay
            selectedSlot = BuddyScheduleSlot.slots(on: firstDay, from: companion.scheduleSlots)
                .first(where: \.bookable)?
                .label
            useCustomTime = false
        } else {
            selectedDay = calendar.startOfDay(for: Date())
            selectedSlot = nil
            // 无可约公开档：引导自定义时间，避免卡在空日。
            useCustomTime = !companion.scheduleSlots.isEmpty
            if useCustomTime {
                scheduledAt = Date.now.addingTimeInterval(60 * 60 * 24)
            }
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
        onBooked(
            resolvedStart,
            hours,
            useCustomTime ? nil : selectedSlot
        )
        onDismiss()
        dismiss()
    }
}
