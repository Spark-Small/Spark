// Module: SparkTrust — Trust score ring progress.

import SwiftUI

public struct TrustScoreRingView: View {
    let profile: TrustProfile

    public init(profile: TrustProfile) {
        self.profile = profile
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(profile.totalScore)")
                        .font(.title.weight(.bold))
                    Text(
                        String(
                            localized: "trust.score.label",
                            defaultValue: "Trust Score",
                            comment: "Trust score label"
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(ringAccessibilityLabel)
        }
    }

    private var progress: CGFloat {
        min(CGFloat(profile.totalScore) / 100.0, 1.0)
    }

    private var ringAccessibilityLabel: String {
        let format = String(
            localized: "trust.ring.a11y.format",
            defaultValue: "信任分 %1$d，满分 100",
            comment: "Trust ring; %1$d score"
        )
        return String(format: format, locale: .current, profile.totalScore)
    }
}

#Preview {
    TrustScoreRingView(
        profile: TrustProfile(totalScore: 65, completedLevels: [.phone, .realName, .liveness])
    )
}
