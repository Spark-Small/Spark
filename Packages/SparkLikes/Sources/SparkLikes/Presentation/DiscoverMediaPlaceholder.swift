// Module: SparkLikes — Mock / failure media placeholder (ambient + centered content).

import SwiftUI

struct DiscoverMediaPlaceholder: View {
    let displayName: String
    let systemImage: String
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(accent.gradient)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Color(.tertiarySystemFill)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                VStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                    if !displayName.isEmpty {
                        Text(displayName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .clipped()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            displayName.isEmpty
                ? String(
                    localized: "likes.media.placeholder.a11y",
                    defaultValue: "推荐照片",
                    comment: "Media placeholder"
                )
                : displayName
        )
    }
}

#Preview {
    DiscoverMediaPlaceholder(
        displayName: "Preview",
        systemImage: "person.fill",
        accent: .purple
    )
    .frame(height: 320)
}
