//
//  InvitationLetterView.swift
//  坐标系
//
//  Scene 7 — paper unfolds from the pocket letter into the login sheet.
//

import SwiftUI

struct InvitationLetterView: View {
    var expansion: CGFloat
    var namespace: Namespace.ID

    var body: some View {
        GeometryReader { geo in
            let t = min(max(expansion, 0), 1)
            // Start size matches EnvelopeView.pocketLetter (~284×172).
            let width = lerp(284, geo.size.width - 24, t)
            let height = lerp(172, geo.size.height - 48, t)
            let radius = lerp(16, 32, t)

            PaperBackground(cornerRadius: radius)
                .matchedGeometryEffect(id: LaunchGeometry.invitationSurface, in: namespace)
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.14 * (1 - t)),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: 0.2 + t * 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.4 + t * 0.5, y: 1)
                    )
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                }
                .overlay {
                    BrandLogo(size: lerp(34, 44, t))
                        .opacity(Double(max(0, 1 - t * 1.15)))
                }
                .frame(width: width, height: height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: lerp(-36, 0, t))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

#Preview {
    @Previewable @Namespace var ns
    InvitationLetterView(expansion: 0.35, namespace: ns)
        .background(InvitationPaper.stage)
}
