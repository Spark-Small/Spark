// Module: SparkActivity — Activity photos gallery on detail (API pending).

import SparkDesignSystem
import SwiftUI

struct ActivityDetailPhotosSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            sectionHeader

            ContentUnavailableView(
                String(
                    localized: "activity.detail.photos.empty.title",
                    defaultValue: "暂无活动照片",
                    comment: "Photos empty title"
                ),
                systemImage: "photo.on.rectangle.angled",
                description: Text(
                    String(
                        localized: "activity.detail.photos.empty.subtitle",
                        defaultValue: "活动结束后，参与者可上传现场照片。",
                        comment: "Photos empty subtitle"
                    )
                )
            )
            .frame(maxWidth: .infinity, minHeight: 160)
            .sparkContentUnavailableCanvas()
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        }
    }

    private var sectionHeader: some View {
        Text(
            String(
                localized: "activity.detail.photos.section",
                defaultValue: "活动照片",
                comment: "Activity photos section"
            )
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.sectionTopPadding)
        .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    ActivityDetailPhotosSection()
}
