// Module: SparkActivity — Live create preview matching inbox list + detail meta.

import SparkDesignSystem
import SwiftUI

/// Mirrors `ActivityInboxListRow` copy hierarchy so hosts see what attendees will see.
struct ActivityCreatePreviewCard: View {
    let draft: CreateActivityDraft
    var coverPreviewImage: Image?
    var coverIsVideo: Bool = false
    var showsDescription: Bool = false

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

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.activityCardContentSpacing) {
            coverHero
                .padding(.top, SparkLayoutMetrics.compactVerticalPadding)

            VStack(alignment: .leading, spacing: 6) {
                if !trimmedCategory.isEmpty {
                    Text(trimmedCategory.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(displayInfo.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(trimmedTitle.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !displayInfo.scheduleParts.isEmpty {
                    previewMetadataLine(
                        parts: displayInfo.scheduleParts,
                        font: .subheadline
                    )
                }

                if let locationText = displayInfo.locationText {
                    Text(locationText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !displayInfo.hostAttendeeParts.isEmpty {
                    previewMetadataLine(
                        parts: displayInfo.hostAttendeeParts,
                        font: .caption
                    )
                }

                registrationMetaRow

                if showsDescription, !draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(draft.description.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, SparkLayoutMetrics.compactVerticalPadding)
                }
            }
            .padding(.bottom, SparkLayoutMetrics.activityCardBottomPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(previewAccessibilityLabel)
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
                .accessibilityLabel(
                    coverIsVideo
                        ? String(
                            localized: "activity.create.preview.cover.video.a11y",
                            defaultValue: "活动封面视频",
                            comment: "Cover video a11y"
                        )
                        : String(
                            localized: "activity.create.preview.cover.image.a11y",
                            defaultValue: "活动封面图片",
                            comment: "Cover image a11y"
                        )
                )
        } else {
            heroPlaceholder
        }
    }

    private var heroPlaceholder: some View {
        RoundedRectangle(
            cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
            style: .continuous
        )
        .fill(.quaternary)
        .aspectRatio(SparkLayoutMetrics.activityCardHeroAspectRatio, contentMode: .fill)
        .overlay {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .accessibilityHidden(true)
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

    private var displayInfo: ActivityListCardDisplayInfo {
        ActivityListCardDisplayInfo(
            title: displayTitle,
            startsAt: draft.startsAt,
            locationName: trimmedLocation.isEmpty
                ? String(
                    localized: "activity.create.preview.location.placeholder",
                    defaultValue: "集合地点",
                    comment: "Preview location placeholder"
                )
                : trimmedLocation,
            hostDisplayName: String(
                localized: "activity.create.preview.host.placeholder",
                defaultValue: "你",
                comment: "Preview host placeholder"
            ),
            attendeeCount: 0,
            capacity: draft.capacity ?? CreateActivityDraft.defaultCapacity
        )
    }

    private func previewMetadataLine(parts: [String], font: Font) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Text("·")
                        .font(font)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                }
                Text(part)
                    .font(font)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewAccessibilityLabel: String {
        displayInfo.accessibilitySummary
    }
}

#Preview {
    ActivityCreatePreviewCard(
        draft: CreateActivityDraft(title: "咖啡小局", locationName: "静安公园", category: "咖啡"),
        showsDescription: true
    )
    .padding()
}
