// Module: SparkActivity — Overlapping attendee initials (Meetup-style "N going" row).

import SparkDesignSystem
import SwiftUI

struct ActivityAttendeeAvatarStack: View {
    let displayNames: [String]
    let attendeeCount: Int
    let maxVisible: Int

    init(displayNames: [String], attendeeCount: Int, maxVisible: Int = 3) {
        self.displayNames = displayNames
        self.attendeeCount = attendeeCount
        self.maxVisible = maxVisible
    }

    init(hostDisplayName: String, attendeeCount: Int, maxVisible: Int = 3) {
        self.init(
            displayNames: hostDisplayName.isEmpty ? [] : [hostDisplayName],
            attendeeCount: attendeeCount,
            maxVisible: maxVisible
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: -SparkLayoutMetrics.activityCardAttendeeOverlap) {
                ForEach(0..<visibleSlotCount, id: \.self) { index in
                    avatar(at: index)
                        .zIndex(Double(visibleSlotCount - index))
                }
            }

            Text(attendeeGoingLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(attendeeGoingLabel)
    }

    private var visibleSlotCount: Int {
        min(max(attendeeCount, 1), maxVisible)
    }

    @ViewBuilder
    private func avatar(at index: Int) -> some View {
        let size = SparkLayoutMetrics.activityCardAttendeeAvatarSize
        if index < displayNames.count, !displayNames[index].isEmpty {
            let name = displayNames[index]
            Text(String(name.prefix(1)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(.quaternary, in: Circle())
                .overlay(Circle().strokeBorder(.background, lineWidth: 2))
        } else {
            Image(systemName: "person.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .background(.quaternary, in: Circle())
                .overlay(Circle().strokeBorder(.background, lineWidth: 2))
                .accessibilityHidden(true)
        }
    }

    private var attendeeGoingLabel: String {
        let format = String(
            localized: "activity.row.going.format",
            defaultValue: "%lld 人参加",
            comment: "Attendee count; %lld is count"
        )
        return String(format: format, locale: .current, attendeeCount)
    }
}

#Preview {
    ActivityAttendeeAvatarStack(displayNames: ["阿乐", "小林", "Mia"], attendeeCount: 5)
        .padding()
}
