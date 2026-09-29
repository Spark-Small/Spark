//
//  BuddyDetailMatchSections.swift
//  坐标系
//
//  搭子详情：匹配、档期、圈子与来源。
//

import SwiftUI
import CoordinateModels

// MARK: - Match / schedule / related

struct BuddyDetailMatchSection: View {
    let profile: BuddyProfile

    private var shared: [String] { BuddyMatchScorer.sharedHobbies(with: profile) }

    var body: some View {
        if shared.isEmpty {
            Text(BuddyMatchScorer.reason(for: profile))
        } else {
            TagFlow(tags: shared)
            Text(BuddyMatchScorer.reason(for: profile))
        }
    }

    var sectionTitle: String {
        shared.isEmpty ? BuddyDetailCopy.reasonTitle : BuddyDetailCopy.matchTitle
    }
}

struct BuddyDetailScheduleSection: View {
    let slots: [String]
    var allowsBooking = false
    var scheduleHint: String? = nil
    var onSelectBookableDay: ((Date) -> Void)? = nil

    @State private var selectedDay: Date?

    var body: some View {
        if slots.isEmpty {
            Text(BuddyDetailCopy.scheduleEmpty)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            BuddyScheduleCalendarView(
                slots: slots,
                selectedDay: Binding(
                    get: { selectedDay },
                    set: { day in
                        selectedDay = day
                        if let day, allowsBooking {
                            onSelectBookableDay?(day)
                        }
                    }
                ),
                allowsSelection: allowsBooking,
                showsMonthPager: true
            )
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)

            if allowsBooking {
                Text(scheduleHint ?? BuddyDetailCopy.scheduleCalendarHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
