//
//  PlatformReviewRatedCard.swift
//  坐标系
//
//  带星级的评价卡片。
//

import SwiftUI

// MARK: - Rated card

struct PlatformReviewRatedCard: View {
    let review: PlatformReview
    var usesFormRowStyle = false
    var showsLike = true
    var isLiked = false
    var isDisliked = false
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil
    var onReply: (() -> Void)? = nil

    private var photoSide: CGFloat { 88 }

    var body: some View {
        if usesFormRowStyle {
            formRowBody
        } else {
            cardRowBody
        }
    }

    private var formRowBody: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(review.author)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)

                if let rating = review.rating {
                    starRow(rating)
                }

                Spacer(minLength: 0)

                Text(Formatters.reviewPostedTime(from: review.postedAt))
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            if let serviceLine = review.serviceLine {
                Text(serviceLine)
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(review.text)
                .font(PlatformListTypography.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if review.hasPhotos {
                photoGrid
            }

            formActionRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var cardRowBody: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
                PlatformListAvatarView(name: review.author, side: 36)

                VStack(alignment: .leading, spacing: metadataSpacing) {
                    Text(review.author)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let rating = review.rating {
                        HStack(spacing: PlatformMetrics.hairlineSpacing) {
                            starRow(rating)
                            if let serviceLine = review.serviceLine {
                                Text("|")
                                    .font(.caption2)
                                    .foregroundStyle(.quaternary)
                                Text(serviceLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    } else if let serviceLine = review.serviceLine {
                        Text(serviceLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Text(review.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if review.hasPhotos {
                photoGrid
            }

            cardActionRow
        }
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .accessibilityElement(children: .combine)
    }

    private var formActionRow: some View {
        HStack {
            if let onReply {
                Button("回复", action: onReply)
                    .font(PlatformListTypography.footnote)
                    .buttonStyle(.borderless)
            }
            Spacer(minLength: 0)
            if showsLike {
                PlatformCommentReactionButtons(
                    isLiked: review.isLiked,
                    isDisliked: review.isDisliked,
                    font: PlatformListTypography.footnote,
                    multicolorLike: false,
                    onLike: onLike,
                    onDislike: onDislike
                )
            }
        }
        .foregroundStyle(.secondary)
    }

    private var cardActionRow: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.minContentGap) {
            Text(Formatters.reviewPostedTime(from: review.postedAt))
                .font(.caption)
                .foregroundStyle(.tertiary)
            if let onReply {
                Button("回复", action: onReply)
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            if showsLike {
                PlatformCommentReactionButtons(
                    isLiked: review.isLiked,
                    isDisliked: review.isDisliked,
                    font: .caption,
                    onLike: onLike,
                    onDislike: onDislike
                )
            }
        }
    }

    private var rowSpacing: CGFloat {
        usesFormRowStyle
            ? PlatformConversationListRow.textToSecondarySpacing
            : PlatformMetrics.cardInfoSpacing
    }

    private var metadataSpacing: CGFloat {
        usesFormRowStyle
            ? PlatformConversationListRow.textToSecondarySpacing
            : PlatformMetrics.hairlineSpacing
    }

    private func starRow(_ rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityLabel("\(rating) 星")
    }

    private var photoGrid: some View {
        HStack(spacing: PlatformMetrics.hairlineSpacing) {
            ForEach(Array(review.photoRefs.prefix(3).enumerated()), id: \.offset) { _, ref in
                CommunityRemotePhoto(ref: ref.communityPhotoRef)
                    .frame(width: photoSide, height: photoSide)
                    .clipShape(RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous))
            }
        }
        .accessibilityLabel("评价配图 \(review.photoRefs.count) 张")
    }
}

