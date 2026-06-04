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
                Rectangle()
                    .fill(.thickMaterial)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                VStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 56))
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
    }
}
