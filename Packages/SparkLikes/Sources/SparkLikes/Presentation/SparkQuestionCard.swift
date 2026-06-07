// Module: SparkLikes — Hinge-style prompt card in profile sheet.

import SparkDesignSystem
import SwiftUI

struct SparkQuestionCard: View {
    let question: SparkQuestion
    var isHighlighted: Bool = false
    var onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.question)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(question.answer)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            HStack {
                Spacer()
                Button(action: onLike) {
                    Image(systemName: isHighlighted ? "heart.fill" : "heart")
                        .foregroundStyle(isHighlighted ? .pink : .secondary)
                }
                .buttonStyle(.sparkPressable)
                .accessibilityLabel(
                    String(
                        localized: "likes.question.like.a11y",
                        defaultValue: "喜欢这条回答",
                        comment: "Like question a11y"
                    )
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sparkGlassSurface(RoundedRectangle.sparkCard)
    }
}

#Preview {
    SparkQuestionCard(
        question: SparkQuestion(id: "1", question: "周末计划", answer: "徒步"),
        onLike: {}
    )
    .padding()
}
