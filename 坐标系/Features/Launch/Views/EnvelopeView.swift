//
//  EnvelopeView.swift
//  坐标系
//
//  Four-flap envelope: rounded card, brand-logo seal,
//  letter slides up from under the flaps on open.
//

import SwiftUI

struct EnvelopeView: View {
    var isFlapOpen: Bool
    var letterRise: CGFloat
    var showsLetter: Bool
    var isFloating: Bool
    var isArriving: Bool
    var namespace: Namespace.ID
    var onTap: () -> Void
    var onOpenFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressScale: CGFloat = 1
    @State private var didReportOpen = false

    private let width: CGFloat = 320
    private let height: CGFloat = 200
    private let cornerRadius: CGFloat = 22

    private var letterOffsetY: CGFloat {
        -letterRise * 76
    }

    var body: some View {
        ZStack {
            groundGlow

            ZStack {
                if showsLetter {
                    pocketLetter
                        .offset(y: letterOffsetY)
                        .zIndex(0)
                }

                flapLayer(.bottom).zIndex(1)
                flapLayer(.left).zIndex(2)
                flapLayer(.right).zIndex(2)
                topFlap
                    .zIndex(3)
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.25) : LaunchMotion.flapOpen,
                        value: isFlapOpen
                    )

                brandSeal
                    .zIndex(4)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.black.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: .black.opacity(0.035), radius: 8, y: 3)
            .shadow(color: .black.opacity(0.065), radius: 28, y: 16)
            .shadow(color: .black.opacity(0.04), radius: 52, y: 30)
            .matchedGeometryEffect(id: LaunchGeometry.envelopeBody, in: namespace, isSource: true)
        }
        .frame(width: width, height: height + 100)
        .scaleEffect(pressScale * (isArriving ? 0.985 : 1))
        .opacity(isArriving ? 0 : 1)
        .floatingAnimation(
            enabled: isFloating && !reduceMotion && !isFlapOpen,
            amplitude: LaunchMotion.floatAmplitude,
            cycle: LaunchMotion.floatCycle
        )
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onTapGesture(perform: handleTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("邀请函")
        .accessibilityHint("打开邀请")
        .accessibilityAddTraits(.isButton)
        .onChange(of: isFlapOpen) { _, open in
            guard open, !didReportOpen else { return }
            Task { @MainActor in
                try? await Task.sleep(for: LaunchMotion.openSequence)
                guard !didReportOpen else { return }
                didReportOpen = true
                onOpenFinished()
            }
        }
    }

    // MARK: - Letter

    private var pocketLetter: some View {
        PaperBackground(cornerRadius: 16, elevated: false)
            .overlay {
                BrandLogo(size: 34)
                    .opacity(0.28 + letterRise * 0.55)
            }
            .frame(width: width - 36, height: height - 28)
            .matchedGeometryEffect(
                id: LaunchGeometry.invitationSurface,
                in: namespace,
                isSource: letterRise < 0.85
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .animation(
                reduceMotion ? .easeOut(duration: 0.25) : LaunchMotion.letterRise,
                value: letterRise
            )
    }

    // MARK: - Flaps

    private var topFlap: some View {
        EnvelopeFlapPolygon(kind: .top, openProgress: isFlapOpen ? 1 : 0)
            .fill(
                LinearGradient(
                    colors: [flapTint(light: true), flapTint(light: false)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                EnvelopeFlapPolygon(kind: .top, openProgress: isFlapOpen ? 1 : 0)
                    .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(isFlapOpen ? 0 : 0.05), radius: 3, y: 1.5)
    }

    private func flapLayer(_ kind: EnvelopeFlapKind) -> some View {
        EnvelopeFlapPolygon(kind: kind, openProgress: 0)
            .fill(
                LinearGradient(
                    colors: flapColors(for: kind),
                    startPoint: kind == .bottom ? .bottom : .top,
                    endPoint: kind == .bottom ? .top : .bottom
                )
            )
            .overlay {
                EnvelopeFlapPolygon(kind: kind, openProgress: 0)
                    .stroke(Color.black.opacity(0.03), lineWidth: 0.45)
            }
    }

    private func flapColors(for kind: EnvelopeFlapKind) -> [Color] {
        switch kind {
        case .top:
            return [flapTint(light: true), flapTint(light: false)]
        case .left, .right:
            return [InvitationPaper.page.opacity(0.94), InvitationPaper.stage.opacity(0.96)]
        case .bottom:
            return [InvitationPaper.stage.opacity(0.98), InvitationPaper.page.opacity(0.92)]
        }
    }

    private func flapTint(light: Bool) -> Color {
        light
            ? Color(red: 0.98, green: 0.97, blue: 0.94)
            : Color(red: 0.94, green: 0.92, blue: 0.88)
    }

    // MARK: - Brand logo seal

    private var brandSeal: some View {
        ZStack {
            Circle()
                .fill(InvitationPaper.page)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            InvitationPaper.accent.opacity(0.55),
                            InvitationPaper.accentDeep.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.1
                )
            BrandLogo(size: 26)
        }
        .frame(width: 48, height: 48)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
        .opacity(isFlapOpen ? 0 : 1)
        .scaleEffect(isFlapOpen ? 0.72 : 1)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.55),
            value: isFlapOpen
        )
        .allowsHitTesting(false)
    }

    private var groundGlow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.black.opacity(0.055),
                        Color.black.opacity(0.018),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: 150
                )
            )
            .frame(width: 260, height: 48)
            .offset(y: height * 0.42)
            .blur(radius: 16)
            .opacity(isArriving ? 0.3 : 1)
            .allowsHitTesting(false)
    }

    private func handleTap() {
        withAnimation(LaunchMotion.pressIn) {
            pressScale = LaunchMotion.pressScale
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(LaunchMotion.pressOut) {
                pressScale = 1
            }
            try? await Task.sleep(for: .milliseconds(50))
            onTap()
        }
    }
}

// MARK: - Flap polygons

enum EnvelopeFlapKind {
    case top, left, right, bottom
}

private struct EnvelopeFlapPolygon: Shape {
    var kind: EnvelopeFlapKind
    var openProgress: CGFloat

    var animatableData: CGFloat {
        get { openProgress }
        set { openProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let topCenter = CGPoint(x: rect.midX, y: rect.minY)

        var path = Path()
        switch kind {
        case .top:
            let apex = CGPoint(
                x: mid.x,
                y: mid.y + (topCenter.y - mid.y) * openProgress
            )
            path.move(to: apex)
            path.addLine(to: tr)
            path.addLine(to: tl)
            path.closeSubpath()
        case .left:
            path.move(to: mid)
            path.addLine(to: tl)
            path.addLine(to: bl)
            path.closeSubpath()
        case .right:
            path.move(to: mid)
            path.addLine(to: tr)
            path.addLine(to: br)
            path.closeSubpath()
        case .bottom:
            path.move(to: mid)
            path.addLine(to: br)
            path.addLine(to: bl)
            path.closeSubpath()
        }
        return path
    }
}

#Preview("Closed") {
    @Previewable @Namespace var ns
    EnvelopeView(
        isFlapOpen: false,
        letterRise: 0,
        showsLetter: true,
        isFloating: true,
        isArriving: false,
        namespace: ns,
        onTap: {},
        onOpenFinished: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(InvitationPaper.stage)
}

#Preview("Opening") {
    @Previewable @Namespace var ns
    EnvelopeView(
        isFlapOpen: true,
        letterRise: 0.85,
        showsLetter: true,
        isFloating: false,
        isArriving: false,
        namespace: ns,
        onTap: {},
        onOpenFinished: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(InvitationPaper.stage)
}
