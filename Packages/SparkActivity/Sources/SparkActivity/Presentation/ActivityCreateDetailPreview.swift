// Module: SparkActivity — Detail-aligned publish preview (mirrors ActivityDetailLoadedList §1–4).

import SparkDesignSystem
import SwiftUI

/// Preview layout modes aligned with attendee-facing surfaces.
enum ActivityCreatePreviewLayout: Sendable {
    case listCard
    case detail
}

struct ActivityCreateDetailPreview: View {
    let draft: CreateActivityDraft
    var coverPreviewImage: Image?
    var coverIsVideo: Bool = false
    var layout: ActivityCreatePreviewLayout = .detail

    var body: some View {
        if layout == .listCard {
            ActivityCreatePreviewCard(
                draft: draft,
                coverPreviewImage: coverPreviewImage,
                coverIsVideo: coverIsVideo,
                showsDescription: false
            )
        } else {
            detailPreviewBody
        }
    }

    private var detailPreviewBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            orientBlock
            decideBlock
            understandBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 1 · Orient

    private var orientBlock: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.activityCardContentSpacing) {
            coverHero
                .padding(.top, SparkLayoutMetrics.compactVerticalPadding)

            VStack(alignment: .leading, spacing: SparkLayoutMetrics.activityCardContentSpacing) {
                if !trimmedCategory.isEmpty {
                    Text(trimmedCategory.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(displayTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(trimmedTitle.isEmpty ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
    }

    // MARK: - 2 · Decide

    private var decideBlock: some View {
        VStack(alignment: .leading, spacing: ActivityDetailMeetupLayout.blockSpacing) {
            scheduleRow
            if !trimmedLocation.isEmpty {
                locationRow
            }
            registrationMetaRow
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
    }

    // MARK: - 3 · Understand

    @ViewBuilder
    private var understandBlock: some View {
        let description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedBlockSpacing) {
                Text(
                    String(
                        localized: "activity.detail.about.section",
                        defaultValue: "简介",
                        comment: "Event description section"
                    )
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            }
            .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
        }
    }

    // MARK: - Rows

    private var scheduleRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(
                ActivityFormatting.detailMeetupScheduleLine(startsAt: draft.startsAt, endsAt: nil)
            )
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var locationRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(trimmedLocation)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var registrationMetaRow: some View {
        HStack(spacing: 8) {
            Text(
                String(localized: "activity.detail.price.free", defaultValue: "免费", comment: "Free event price")
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .sparkGlassControl(Capsule())

            Text(
                ActivityFormatting.attendeeLine(
                    attendeeCount: 0,
                    capacity: draft.capacity ?? CreateActivityDraft.defaultCapacity
                )
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, SparkLayoutMetrics.compactVerticalPadding)
    }

    @ViewBuilder
    private var coverHero: some View {
        if let coverPreviewImage {
            coverPreviewImage
                .resizable()
                .scaledToFill()
                .aspectRatio(SparkLayoutMetrics.activityCardHeroAspectRatio, contentMode: .fill)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
                        style: .continuous
                    )
                )
                .overlay {
                    if coverIsVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityHidden(true)
                    }
                }
        } else {
            RoundedRectangle(
                cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
                style: .continuous
            )
            .fill(.quaternary)
            .aspectRatio(SparkLayoutMetrics.activityCardHeroAspectRatio, contentMode: .fill)
            .overlay {
                Image(systemName: coverIsVideo ? "video.fill" : "photo")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Copy

    private var trimmedTitle: String {
        draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLocation: String {
        draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCategory: String {
        draft.category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayTitle: String {
        if trimmedTitle.isEmpty {
            return String(
                localized: "activity.create.preview.title.placeholder",
                defaultValue: "局名",
                comment: "Preview title placeholder"
            )
        }
        return trimmedTitle
    }
}

#Preview("Detail layout") {
    ScrollView {
        ActivityCreateDetailPreview(
            draft: CreateActivityDraft(
                title: "咖啡小局",
                description: "轻松见面聊聊。",
                locationName: "静安公园",
                category: "咖啡"
            ),
            layout: .detail
        )
    }
    .background(.background)
}
