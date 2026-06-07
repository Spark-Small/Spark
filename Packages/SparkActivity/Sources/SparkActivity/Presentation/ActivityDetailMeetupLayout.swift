// Module: SparkActivity — Meetup-style detail scroll layout helpers.

import SparkDesignSystem
import SwiftUI

enum ActivityDetailMeetupLayout {
    static let contentSpacing: CGFloat = 16
    static let blockSpacing: CGFloat = 12
    static let sectionTopPadding: CGFloat = 28

    static var horizontalPadding: CGFloat {
        SparkLayoutMetrics.standardHorizontalPadding
    }
}

extension ActivityDetailLoadedList {
    func meetupDetailSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.sectionTopPadding)
            .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
            .accessibilityAddTraits(.isHeader)
    }

    func meetupDetailSubsectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.sectionTopPadding)
            .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
            .accessibilityAddTraits(.isHeader)
    }

    func meetupInsetActionsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous))
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.blockSpacing)
    }

    func meetupActionDivider() -> some View {
        Divider()
            .padding(.leading, ActivityDetailMeetupLayout.horizontalPadding)
    }

    func meetupNoticeBlock(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.blockSpacing)
    }
}
