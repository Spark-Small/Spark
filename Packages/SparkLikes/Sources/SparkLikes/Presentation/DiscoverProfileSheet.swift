// Module: SparkLikes — Half-sheet profile detail (swipe-up / tap bio).

import SparkCore
import SparkTrust
import SwiftUI

struct DiscoverProfileSheet: View {
    let card: DiscoverCard
    var highlightedQuestionID: String?
    var onLikeQuestion: (String) -> Void = { _ in }
    let onReport: () -> Void
    var onOpenSharedActivity: ((String) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        if let trustScore = card.trustScore {
                            TrustBadgeView(
                                score: trustScore,
                                hasLiveness: card.hasLivenessVerification
                            )
                        }
                        Spacer()
                        if card.activityAttendanceCount > 0 {
                            Text(attendanceLine(count: card.activityAttendanceCount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !card.bio.isEmpty {
                        Text(card.bio)
                    }
                    if let location = card.coarseLocation {
                        Label(location, systemImage: "location")
                    }
                    if let activity = card.sharedActivityTitle {
                        if let activityID = card.sharedActivityID {
                            Button {
                                dismiss()
                                onOpenSharedActivity?(activityID)
                            } label: {
                                Label(activity, systemImage: "calendar")
                            }
                        } else {
                            Label(activity, systemImage: "calendar")
                        }
                    }
                } header: {
                    Text(
                        String(
                            localized: "likes.profile.trust.header",
                            defaultValue: "信任档案",
                            comment: "Trust profile header"
                        )
                    )
                }

                if !card.interestTags.isEmpty {
                    Section(
                        String(
                            localized: "likes.profile.interests",
                            defaultValue: "兴趣",
                            comment: "Interests section"
                        )
                    ) {
                        FlowTagsView(tags: card.interestTags)
                    }
                }

                if !card.sparkQuestions.isEmpty {
                    Section(
                        String(
                            localized: "likes.profile.sparkQuestions",
                            defaultValue: "火花问题",
                            comment: "Spark questions section"
                        )
                    ) {
                        ForEach(card.sparkQuestions.prefix(3)) { question in
                            SparkQuestionCard(
                                question: question,
                                isHighlighted: highlightedQuestionID == question.id,
                                onLike: { onLikeQuestion(question.id) }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                    }
                }

                Section {
                    Button(
                        String(
                            localized: "likes.report.block",
                            defaultValue: "举报并屏蔽",
                            comment: "Report"
                        ),
                        role: .destructive
                    ) {
                        dismiss()
                        onReport()
                    }
                }
            }
            .navigationTitle(card.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func attendanceLine(count: Int) -> String {
        let format = String(
            localized: "likes.profile.attendance.format",
            defaultValue: "参加过 %lld 场活动",
            comment: "Activity attendance count"
        )
        return String(format: format, locale: .current, count)
    }
}

private struct FlowTagsView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }
}

#Preview {
    DiscoverProfileSheet(
        card: DiscoverCard(
            userID: UserID("preview"),
            displayName: "Preview",
            bio: "Bio",
            gender: .female,
            media: DiscoverMedia(kind: .image, url: URL(string: "https://example.com/a.jpg")!),
            interestTags: ["咖啡", "徒步"],
            trustScore: 65,
            hasLivenessVerification: true,
            activityAttendanceCount: 3
        ),
        onReport: {}
    )
}
