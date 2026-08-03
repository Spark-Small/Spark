//
//  BuddyScheduleCalendarView.swift
//  坐标系
//
//  陪玩档期月历：日期下显示可约 / 已满 / 待开放。
//

import SwiftUI

struct BuddyScheduleCalendarView: View {
    let slots: [String]
    @Binding var selectedDay: Date?
    var allowsSelection = true
    var showsMonthPager = true

    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var visibleMonth: Date = Date()

    private var availability: [Date: BuddyScheduleSlot.DayAvailability] {
        BuddyScheduleSlot.dayAvailabilityMap(slots: slots, calendar: calendar)
    }

    private var monthTitle: String {
        visibleMonth.formatted(
            Date.FormatStyle()
                .year()
                .month(.wide)
                .locale(Locale(identifier: "zh_CN"))
        )
    }

    private var weekdaySymbols: [String] {
        var cal = calendar
        cal.locale = Locale(identifier: "zh_CN")
        // 日一二三四五六
        let symbols = cal.veryShortWeekdaySymbols
        let first = cal.firstWeekday - 1
        guard first > 0, first < symbols.count else { return symbols }
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 0
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in 0..<dayCount {
            if let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                cells.append(calendar.startOfDay(for: date))
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
            if showsMonthPager {
                monthHeader
            } else {
                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                spacing: PlatformMetrics.minContentGap
            ) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear
                            .frame(minHeight: cellMinHeight)
                    }
                }
            }
        }
        .onAppear {
            alignVisibleMonth()
        }
        .onChange(of: selectedDay) { _, _ in
            alignVisibleMonth()
        }
        .onChange(of: slots) { _, _ in
            alignVisibleMonth()
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("上个月")

            Spacer()
            Text(monthTitle)
                .font(.subheadline.weight(.semibold))
            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("下个月")
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let status = availability[calendar.startOfDay(for: day)] ?? .none
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isToday = calendar.isDateInToday(day)
        let past = day < calendar.startOfDay(for: Date())
        let selectable = allowsSelection && status.isSelectable && !past

        Button {
            guard selectable else { return }
            selectedDay = day
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.body.weight(isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(dayNumberColor(selected: isSelected, past: past, status: status))

                Text(status.caption ?? " ")
                    .font(.system(size: captionFontSize, weight: .medium))
                    .foregroundStyle(captionColor(status, selected: isSelected))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: cellMinHeight)
            .padding(.vertical, 4)
            .background(cellBackground(selected: isSelected, status: status), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
        .accessibilityLabel(accessibilityLabel(day: day, status: status))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var cellMinHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 56 : 44
    }

    private var captionFontSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 11 : 9
    }

    private func dayNumberColor(
        selected: Bool,
        past: Bool,
        status: BuddyScheduleSlot.DayAvailability
    ) -> Color {
        if selected { return .white }
        if past { return .secondary.opacity(0.45) }
        if status == .bookable { return .primary }
        return .secondary
    }

    private func captionColor(
        _ status: BuddyScheduleSlot.DayAvailability,
        selected: Bool
    ) -> Color {
        if selected { return .white.opacity(0.92) }
        switch status {
        case .bookable: return PlatformStatus.success
        case .full: return PlatformStatus.danger
        case .pending: return PlatformStatus.warning
        case .none: return .clear
        }
    }

    private func cellBackground(
        selected: Bool,
        status: BuddyScheduleSlot.DayAvailability
    ) -> Color {
        if selected { return Color.accentColor }
        if status == .bookable { return Color.accentColor.opacity(0.08) }
        return .clear
    }

    private func accessibilityLabel(day: Date, status: BuddyScheduleSlot.DayAvailability) -> String {
        let dateText = day.formatted(
            Date.FormatStyle()
                .month()
                .day()
                .locale(Locale(identifier: "zh_CN"))
        )
        if let caption = status.caption {
            return "\(dateText)，\(caption)"
        }
        return dateText
    }

    private func shiftMonth(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: visibleMonth) {
            visibleMonth = next
        }
    }

    private func alignVisibleMonth() {
        if let selectedDay {
            visibleMonth = calendar.startOfDay(for: selectedDay)
            return
        }
        if let firstBookable = availability
            .filter({ $0.value == .bookable })
            .map(\.key)
            .sorted()
            .first
        {
            visibleMonth = firstBookable
            return
        }
        visibleMonth = calendar.startOfDay(for: Date())
    }
}
