//
//  EnvelopeView.swift
//  坐标系
//
//  红色圆角信封：点击后四叶草顺时针解锁，上盖翻开，信纸升起并衔接到登录页。
//

import SwiftUI

struct EnvelopeView: View {
    var isFlapOpen: Bool
    var isLetterInteractive: Bool
    var letterRise: CGFloat
    var isFloating: Bool
    var namespace: Namespace.ID
    var onTap: () -> Void
    var onOpenFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressScale: CGFloat = 1
    @State private var didReportOpen = false
    @State private var visualOpen = false
    @State private var flapHidden = false
    @State private var letterOut = false
    @State private var sealRotation: Double = 0
    @State private var sealVisible = true
    @State private var weather = GreetingWeatherStore.shared

    private let width: CGFloat = 356
    private let height: CGFloat = 252
    private let cornerRadius: CGFloat = 48

    private var letterOffsetY: CGFloat {
        -(letterOut ? letterRise : 0) * 86
    }

    var body: some View {
        ZStack {
            groundGlow

            ZStack {
                envelopeBody

                pocketLetter
                    .offset(y: letterOffsetY)
                    .opacity(letterOut ? 1 : 0)
                    .zIndex(1)

                frontPocket
                    .zIndex(2)

                topFlap
                    .zIndex(3)

                flapSeam
                    .zIndex(4)

                cloverSeal
                    .zIndex(5)

                if !isFlapOpen {
                    Button(action: handleTap) {
                        Color.clear
                            .contentShape(envelopeShape)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("打开四叶草邀请函")
                    .accessibilityHint("旋转四叶草并露出信纸")
                    .zIndex(6)
                }
            }
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
        }
        // 预留信纸升起后的高度，避免露出的部分落在命中区域之外。
        .frame(width: width, height: height + 200)
        .scaleEffect(pressScale)
        .floatingAnimation(
            enabled: isFloating && !reduceMotion && !isFlapOpen,
            amplitude: LaunchMotion.floatAmplitude,
            cycle: LaunchMotion.floatCycle
        )
        .onChange(of: isFlapOpen) { _, open in
            guard open, !didReportOpen else { return }
            unlockEnvelope()
            Task { @MainActor in
                try? await Task.sleep(
                    for: reduceMotion ? .milliseconds(150) : LaunchMotion.openSequence
                )
                guard !didReportOpen else { return }
                didReportOpen = true
                onOpenFinished()
            }
        }
        .task {
            await LaunchWeather.refreshIfAuthorized(weather)
        }
    }

    // MARK: - Letter

    @ViewBuilder
    private var pocketLetter: some View {
        if isLetterInteractive {
            NavigationLink(value: LaunchState.login) {
                letterSurface
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(
                id: LaunchGeometry.invitationSurface,
                in: namespace
            ) { source in
                source.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .accessibilityLabel("进入登录页面")
            .accessibilityHint("信纸将放大为登录页面")
        } else {
            letterSurface
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var letterSurface: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(LaunchSurface.invitationPaper)
            .overlay {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    invitationLetterContent(at: context.date)
                }
            }
            .frame(width: width - 36, height: height - 28)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
            .animation(
                reduceMotion ? .easeOut(duration: 0.25) : LaunchMotion.letterRise,
                value: letterOut
            )
    }

    private func invitationLetterContent(at date: Date) -> some View {
        let note = InvitationNote.make(date: date, weather: weather.reading)

        return ZStack {
            InvitationPaperArtwork(systemImage: note.systemImage)

            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(
                        date,
                        format: .dateTime
                            .month()
                            .day()
                            .weekday(.wide)
                            .hour()
                            .minute()
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(note.salutation)
                        .padding(.top, 18)

                    Text(note.message)
                        .padding(.top, 4)
                        .lineSpacing(4)

                    HStack {
                        Spacer()
                        Text("坐标系")
                            .font(.custom("STKaitiSC-Regular", size: 16, relativeTo: .body))
                    }
                    .padding(.top, 9)
                }
                .font(.custom("STKaitiSC-Regular", size: 18, relativeTo: .body))
                .foregroundStyle(.primary.opacity(0.84))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                weatherDoodle(note: note)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func weatherDoodle(note: InvitationNote) -> some View {
        VStack(spacing: 2) {
            Image(systemName: note.systemImage)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 30, weight: .regular))

            if let temperature = note.temperatureC {
                Text("\(temperature)°")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 52, height: 52)
        .background(.thinMaterial, in: Circle())
        .accessibilityHidden(true)
    }

    // MARK: - Red envelope

    /// 信封主体、前袋、上盖共用同一渐变，避免接缝处出现色带。
    private var envelopeFill: LinearGradient {
        LinearGradient(
            colors: [LaunchSurface.envelopeLift, LaunchSurface.envelope, LaunchSurface.envelopeDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var envelopeShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var envelopeBody: some View {
        envelopeShape
            .fill(envelopeFill)
            .allowsHitTesting(false)
    }

    /// 装饰层不接收点击，否则会挡住信纸下半部分的进入手势。
    private var frontPocket: some View {
        EnvelopeFrontPocketShape(corner: cornerRadius)
            .fill(envelopeFill)
            .clipShape(envelopeShape)
            .allowsHitTesting(false)
    }

    private var topFlap: some View {
        EnvelopeTopFlapShape(corner: cornerRadius)
            .fill(envelopeFill)
            .clipShape(envelopeShape)
            .rotation3DEffect(
                .degrees(visualOpen ? -172 : 0),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top,
                perspective: 0.5
            )
            .animation(
                reduceMotion ? .easeOut(duration: 0.25) : LaunchMotion.flapOpen,
                value: visualOpen
            )
            .opacity(flapHidden ? 0 : 1)
            .animation(LaunchMotion.flapVanish, value: flapHidden)
            .allowsHitTesting(!flapHidden)
    }

    /// 前袋的白色封口线，上盖翻开后依旧保留，与图标保持一致。
    private var flapSeam: some View {
        EnvelopeFlapCurve(corner: cornerRadius)
            .stroke(
                Color.white,
                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
            )
            .clipShape(envelopeShape)
            .allowsHitTesting(false)
    }

    // MARK: - Clover seal

    private var cloverSeal: some View {
        CloverShape()
            .fill(Color.white)
            .frame(width: 84, height: 84)
            .rotationEffect(.degrees(sealRotation))
            .scaleEffect(sealVisible ? 1 : 0.82)
            .opacity(sealVisible ? 1 : 0)
            .offset(y: height * (EnvelopeMetrics.curveBottomRatio - 0.5))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
            .offset(y: height * 0.46)
            .blur(radius: 16)
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

    private func unlockEnvelope() {
        guard !visualOpen else { return }
        if reduceMotion {
            visualOpen = true
            flapHidden = true
            letterOut = true
            sealVisible = false
            return
        }

        withAnimation(LaunchMotion.cloverUnlock) {
            sealRotation = 90
        }
        Task { @MainActor in
            try? await Task.sleep(for: LaunchMotion.cloverUnlockDuration)
            withAnimation(LaunchMotion.flapOpen) { visualOpen = true }
            withAnimation(LaunchMotion.sealFade) { sealVisible = false }

            try? await Task.sleep(for: LaunchMotion.flapVanishDelay)
            withAnimation(LaunchMotion.flapVanish) { flapHidden = true }

            try? await Task.sleep(for: LaunchMotion.letterRiseDelay)
            withAnimation(LaunchMotion.letterRise) { letterOut = true }
        }
    }
}

// MARK: - Envelope shapes

/// 抛物封口线的统一几何：上盖、前袋、白线三者共用，保证边界完全重合。
private enum EnvelopeMetrics {
    /// 曲线最低点（四叶草中心）在信封高度上的比例。
    static let curveBottomRatio: CGFloat = 0.52

    /// 曲线端点落在圆角 45° 处，视觉上从两个上角自然发出。
    static func anchorInset(corner: CGFloat) -> CGFloat {
        corner * (1 - 1 / sqrt(2))
    }

    /// 从左端点经中心到右端点的封口曲线。
    static func curve(in rect: CGRect, corner: CGFloat) -> Path {
        let inset = anchorInset(corner: corner)
        let start = CGPoint(x: rect.minX + inset, y: rect.minY + inset)
        let end = CGPoint(x: rect.maxX - inset, y: rect.minY + inset)
        let bottom = CGPoint(x: rect.midX, y: rect.minY + rect.height * curveBottomRatio)

        var path = Path()
        path.move(to: start)
        path.addCurve(
            to: bottom,
            control1: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.28),
            control2: CGPoint(x: rect.minX + rect.width * 0.29, y: bottom.y)
        )
        path.addCurve(
            to: end,
            control1: CGPoint(x: rect.minX + rect.width * 0.71, y: bottom.y),
            control2: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.minY + rect.height * 0.28)
        )
        return path
    }
}

private struct EnvelopeFlapCurve: Shape {
    var corner: CGFloat

    func path(in rect: CGRect) -> Path {
        EnvelopeMetrics.curve(in: rect, corner: corner)
    }
}

/// 封口线以上的区域，翻开时整体绕上边旋转。
private struct EnvelopeTopFlapShape: Shape {
    var corner: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = EnvelopeMetrics.anchorInset(corner: corner)
        let shoulder = rect.minY + inset

        var path = EnvelopeMetrics.curve(in: rect, corner: corner)
        path.addLine(to: CGPoint(x: rect.maxX, y: shoulder))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: shoulder))
        path.closeSubpath()
        return path
    }
}

/// 封口线以下的区域，始终遮住信纸下半部分。
private struct EnvelopeFrontPocketShape: Shape {
    var corner: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = EnvelopeMetrics.anchorInset(corner: corner)
        let shoulder = rect.minY + inset

        var path = EnvelopeMetrics.curve(in: rect, corner: corner)
        path.addLine(to: CGPoint(x: rect.maxX, y: shoulder))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: shoulder))
        path.closeSubpath()
        return path
    }
}

/// 四片心形叶合成一条路径，避免相互叠加时出现抗锯齿缝隙。
private struct CloverShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let length = min(rect.width, rect.height) / 2
        let leaf = heartLeaf(length: length)

        var path = Path()
        for index in 0..<4 {
            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: .pi / 2 * Double(index))
            path.addPath(leaf, transform: transform)
        }
        return path
    }

    /// 尖端在原点、朝上生长的心形。尖端两侧约 ±37°，四片拼合后留出清晰的 V 形缺口。
    private func heartLeaf(length l: CGFloat) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addCurve(
            to: CGPoint(x: -0.48 * l, y: -0.58 * l),
            control1: CGPoint(x: -0.21 * l, y: -0.28 * l),
            control2: CGPoint(x: -0.44 * l, y: -0.40 * l)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: -0.76 * l),
            control1: CGPoint(x: -0.50 * l, y: -0.84 * l),
            control2: CGPoint(x: -0.22 * l, y: -0.94 * l)
        )
        path.addCurve(
            to: CGPoint(x: 0.48 * l, y: -0.58 * l),
            control1: CGPoint(x: 0.22 * l, y: -0.94 * l),
            control2: CGPoint(x: 0.50 * l, y: -0.84 * l)
        )
        path.addCurve(
            to: .zero,
            control1: CGPoint(x: 0.44 * l, y: -0.40 * l),
            control2: CGPoint(x: 0.21 * l, y: -0.28 * l)
        )
        path.closeSubpath()
        return path
    }
}

#Preview("Closed") {
    @Previewable @Namespace var ns
    EnvelopeView(
        isFlapOpen: false,
        isLetterInteractive: false,
        letterRise: 0,
        isFloating: true,
        namespace: ns,
        onTap: {},
        onOpenFinished: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LaunchSurface.stage)
}

#Preview("Opening") {
    @Previewable @Namespace var ns
    EnvelopeView(
        isFlapOpen: true,
        isLetterInteractive: true,
        letterRise: 0.85,
        isFloating: false,
        namespace: ns,
        onTap: {},
        onOpenFinished: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LaunchSurface.stage)
}
