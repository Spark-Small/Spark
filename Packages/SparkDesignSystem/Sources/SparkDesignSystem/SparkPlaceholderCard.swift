// Module: SparkDesignSystem — List row placeholder content.

import SwiftUI

/// List row placeholder content — uses system backgrounds (no Liquid Glass in scroll content).
public struct SparkPlaceholderCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    public init(title: String, subtitle: String, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

#Preview {
    List {
        SparkPlaceholderCard(
            title: "Recommendation",
            subtitle: "Trending",
            systemImage: "sparkles"
        )
    }
}
