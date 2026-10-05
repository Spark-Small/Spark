//
//  BuddyDetailMatchSections.swift
//  坐标系
//
//  搭子详情：档期、圈子与来源（推荐理由见 BuddyDetailAboutSection）。
//

import SwiftUI
import CoordinateModels

// MARK: - Schedule / related
// 「推荐理由」文案 + 胶囊已并入 `BuddyDetailAboutSection`。

struct BuddyDetailScheduleSection: View {
    let slots: [String]
    var allowsBooking = false
    var scheduleHint: String? = nil
    var onSelectBookableDay: ((Date) -> Void)? = nil

    @Environment(\.calendar) private var calendar
    @State private var selectedDay: Date?
    @State private var didSeedSelection = false

    var body: some View {
        if slots.isEmpty {
            Text(BuddyDetailCopy.scheduleEmpty)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            BuddyScheduleCalendarView(
                slots: slots,
                selectedDay: $selectedDay,
                allowsSelection: allowsBooking,
                showsMonthPager: true,
                onConfirmDay: allowsBooking ? onSelectBookableDay : nil
            )
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
            .onAppear(perform: seedSelectionIfNeeded)

            if allowsBooking {
                Text(scheduleHint ?? BuddyDetailCopy.scheduleCalendarHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 预高亮最近可约日，不触发预约 / 邀约。
    private func seedSelectionIfNeeded() {
        guard !didSeedSelection else { return }
        didSeedSelection = true
        guard selectedDay == nil else { return }
        selectedDay = BuddyScheduleSlot.firstBookableDay(slots: slots, calendar: calendar)
    }
}

struct BuddyDetailCircleRow: View {
    let circleName: String
    let topic: String
    var profileSource: BuddyProfileSource = .discover

    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabNavigationStateRef) private var navigation
    @Environment(BuddiesModel.self) private var buddies

    private var circle: InterestCircle? {
        buddies.circle(named: circleName)
    }

    /// 从圈子信息进入时，栈下已有圈子页 —— 官方做法是用 dismiss 回退，而非再 push
    private var shouldReturnToCircle: Bool {
        profileSource.isCircleSource(named: circleName)
    }

    var body: some View {
        if shouldReturnToCircle, circle != nil {
            Button(action: returnToCircle) {
                circleLabel
            }
            .accessibilityHint(BuddyDetailCopy.returnToCircleHint)
        } else if let circle {
            NavigationLink(value: CircleBrowseRoute.circle(circle)) {
                circleLabel
            }
            .accessibilityHint(BuddyDetailCopy.openCircleHint)
        } else {
            circleLabel
        }
    }

    private func returnToCircle() {
        guard let navigation else {
            dismiss()
            return
        }
        if navigation.path.count > 1 {
            navigation.popLast()
        } else if !navigation.isEmpty {
            navigation.reset()
            dismiss()
        } else {
            dismiss()
        }
    }

    private var circleLabel: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                Text(circleName)
                    .font(.body)
                Text(topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: circle?.systemImage ?? "person.3")
                .foregroundStyle(.tint)
        }
    }
}

/// 从圈子 / 工会 / 语音厅进入时的来源说明行
struct BuddyDetailSourceRow: View {
    let line: String
    var source: BuddyProfileSource

    private var systemImage: String {
        switch source {
        case .discover: "sparkles"
        case .circle: "person.3"
        case .guild: "building.2"
        case .voiceHall: "dot.radiowaves.left.and.right"
        }
    }

    var body: some View {
        Label {
            Text(line)
                .font(.body)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
        }
        .accessibilityElement(children: .combine)
    }
}
