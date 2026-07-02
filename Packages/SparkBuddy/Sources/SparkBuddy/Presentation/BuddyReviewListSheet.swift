// Module: SparkBuddy — Full review list sheet.

import SparkDesignSystem
import SwiftUI

struct BuddyReviewListSheet: View {
  @State private var viewModel: BuddyReviewListViewModel
  @Environment(\.dismiss) private var dismiss

  init(viewModel: BuddyReviewListViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    NavigationStack {
      Group {
        switch viewModel.state {
        case .loading where viewModel.reviews.isEmpty:
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failure(let message) where viewModel.reviews.isEmpty:
          SparkRetryUnavailableView(
            title: String(
              localized: "buddy.reviews.error.title",
              defaultValue: "无法加载评价",
              comment: "Reviews load error title"
            ),
            description: message
          ) {
            Task { await viewModel.reload() }
          }
        default:
          reviewList
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
    .task { await viewModel.loadInitialIfNeeded() }
  }

  private var reviewList: some View {
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
            viewModel.reviewCount
          )
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }

      Section {
        ForEach(viewModel.reviews) { review in
          reviewRow(review)
            .task { await viewModel.loadMoreIfNeeded(for: review) }
        }
        if viewModel.isLoadingMore {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          .listRowSeparator(.hidden)
        }
      }
    }
  }

  private func reviewRow(_ review: BuddyReview) -> some View {
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

#Preview("Buddy review list") {
  BuddyReviewListSheet(
    viewModel: BuddyReviewListViewModel(
      listingID: "buddy_city_1",
      reviewCount: 54,
      fetchReviews: FetchBuddyReviewsUseCase(repository: MockBuddyRepository())
    )
  )
}
