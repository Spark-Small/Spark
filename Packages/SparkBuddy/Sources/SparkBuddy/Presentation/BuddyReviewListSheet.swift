// Module: SparkBuddy — Full review list sheet.

import SparkDesignSystem
import SwiftUI

struct BuddyReviewListSheet: View {
    let reviewCount: Int
    let reviews: [BuddyReview]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(
                        String(
                            format: String(
                                localized: "buddy.reviews.sheet.summary.format",
                                defaultValue: "共 %lld 条用户评价",
                                comment: "Review sheet summary; count"
                            ),
                            locale: .current,
                            reviewCount
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Section {
                    ForEach(reviews) { review in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(review.authorDisplayName)
                                    .font(.subheadline.weight(.semibold))
                                Spacer(minLength: 8)
                                BuddyStarRatingView(rating: review.rating, starSize: .caption2)
                            }
                            Text(review.comment)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let createdAt = review.createdAt {
                                Text(BuddyFormatting.reviewDateText(createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .navigationTitle(
                String(
                    localized: "buddy.reviews.sheet.title",
                    defaultValue: "全部评价",
                    comment: "All reviews sheet title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done", defaultValue: "完成", comment: "Done")) {
                        dismiss()
                    }
                }
            }
            .sparkPhoneStyleNavigationBar()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Buddy review list") {
    BuddyReviewListSheet(
        reviewCount: 54,
        reviews: [
            BuddyReview(
                id: "1",
                authorDisplayName: "小林",
                rating: 5,
                comment: "路线规划很贴心，会提前问我想逛什么。",
                createdAt: .now
            )
        ]
    )
}
