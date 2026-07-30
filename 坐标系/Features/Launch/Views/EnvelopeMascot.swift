//
//  EnvelopeMascot.swift
//  坐标系
//
//  登录页信头左侧的挥手信封小人。
//

import SwiftUI

struct EnvelopeMascot: View {
    @ScaledMetric(relativeTo: .title2) private var envelopeHeight: CGFloat = 42

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let centerX = proxy.size.width / 2
            let envelopeTop = height * 0.14
            let envelopeBottom = envelopeTop + envelopeHeight
            let leftHand = CGPoint(
                x: centerX - envelopeHeight * 0.91,
                y: envelopeTop + envelopeHeight * 0.14
            )
            let rightHand = CGPoint(
                x: centerX + envelopeHeight * 0.91,
                y: envelopeTop + envelopeHeight * 0.65
            )
            let limbColor = Color.red.opacity(0.68)

            Canvas { context, _ in
                drawLimbs(
                    in: &context,
                    centerX: centerX,
                    envelopeTop: envelopeTop,
                    envelopeBottom: envelopeBottom,
                    height: height,
                    leftHand: leftHand,
                    rightHand: rightHand,
                    limbColor: limbColor
                )
                drawHands(in: &context, leftHand: leftHand, rightHand: rightHand, limbColor: limbColor)
                drawShoes(in: &context, centerX: centerX, height: height, limbColor: limbColor)
                drawWaveMarks(in: &context, leftHand: leftHand)
            }

            Image("BrandLogo")
                .interpolation(.high)
                .resizable()
                .scaledToFill()
                .scaleEffect(1.06)
                .frame(width: envelopeHeight * 1.4, height: envelopeHeight)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: envelopeHeight * 0.22,
                        style: .continuous
                    )
                )
                .position(x: centerX, y: envelopeTop + envelopeHeight / 2)
        }
        .frame(width: envelopeHeight * 2.1, height: envelopeHeight * 1.52)
        .rotationEffect(.degrees(-1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("挥手的信封小人")
    }

    private func drawLimbs(
        in context: inout GraphicsContext,
        centerX: CGFloat,
        envelopeTop: CGFloat,
        envelopeBottom: CGFloat,
        height: CGFloat,
        leftHand: CGPoint,
        rightHand: CGPoint,
        limbColor: Color
    ) {
        let stroke = StrokeStyle(
            lineWidth: max(2, envelopeHeight * 0.055),
            lineCap: .round,
            lineJoin: .round
        )
        var limbs = Path()

        limbs.move(
            to: CGPoint(
                x: centerX - envelopeHeight * 0.66,
                y: envelopeTop + envelopeHeight * 0.48
            )
        )
        limbs.addCurve(
            to: leftHand,
            control1: CGPoint(
                x: centerX - envelopeHeight * 0.78,
                y: envelopeTop + envelopeHeight * 0.43
            ),
            control2: CGPoint(
                x: centerX - envelopeHeight * 0.80,
                y: envelopeTop + envelopeHeight * 0.22
            )
        )
        limbs.move(
            to: CGPoint(
                x: centerX + envelopeHeight * 0.66,
                y: envelopeTop + envelopeHeight * 0.50
            )
        )
        limbs.addCurve(
            to: rightHand,
            control1: CGPoint(
                x: centerX + envelopeHeight * 0.78,
                y: envelopeTop + envelopeHeight * 0.50
            ),
            control2: CGPoint(
                x: centerX + envelopeHeight * 0.82,
                y: envelopeTop + envelopeHeight * 0.62
            )
        )
        limbs.move(to: CGPoint(x: centerX - envelopeHeight * 0.23, y: envelopeBottom - 1))
        limbs.addCurve(
            to: CGPoint(x: centerX - envelopeHeight * 0.30, y: height * 0.83),
            control1: CGPoint(x: centerX - envelopeHeight * 0.22, y: height * 0.71),
            control2: CGPoint(x: centerX - envelopeHeight * 0.28, y: height * 0.78)
        )
        limbs.move(to: CGPoint(x: centerX + envelopeHeight * 0.23, y: envelopeBottom - 1))
        limbs.addCurve(
            to: CGPoint(x: centerX + envelopeHeight * 0.30, y: height * 0.83),
            control1: CGPoint(x: centerX + envelopeHeight * 0.22, y: height * 0.71),
            control2: CGPoint(x: centerX + envelopeHeight * 0.28, y: height * 0.78)
        )

        context.stroke(limbs, with: .color(limbColor), style: stroke)
    }

    private func drawHands(
        in context: inout GraphicsContext,
        leftHand: CGPoint,
        rightHand: CGPoint,
        limbColor: Color
    ) {
        let handRadius = envelopeHeight * 0.095
        let outline = StrokeStyle(lineWidth: max(1.4, envelopeHeight * 0.035))
        for hand in [leftHand, rightHand] {
            let glove = Path(
                ellipseIn: CGRect(
                    x: hand.x - handRadius,
                    y: hand.y - handRadius,
                    width: handRadius * 2,
                    height: handRadius * 2
                )
            )
            context.fill(glove, with: .color(LaunchSurface.invitationPaper))
            context.stroke(glove, with: .color(limbColor), style: outline)
        }
    }

    private func drawShoes(
        in context: inout GraphicsContext,
        centerX: CGFloat,
        height: CGFloat,
        limbColor: Color
    ) {
        let shoeSize = CGSize(width: envelopeHeight * 0.30, height: envelopeHeight * 0.13)
        for x in [centerX - envelopeHeight * 0.36, centerX + envelopeHeight * 0.36] {
            let shoe = Path(
                ellipseIn: CGRect(
                    x: x - shoeSize.width / 2,
                    y: height * 0.81,
                    width: shoeSize.width,
                    height: shoeSize.height
                )
            )
            context.fill(shoe, with: .color(limbColor))
        }
    }

    private func drawWaveMarks(in context: inout GraphicsContext, leftHand: CGPoint) {
        var wave = Path()
        wave.move(
            to: CGPoint(
                x: leftHand.x - envelopeHeight * 0.18,
                y: leftHand.y - envelopeHeight * 0.03
            )
        )
        wave.addLine(
            to: CGPoint(
                x: leftHand.x - envelopeHeight * 0.27,
                y: leftHand.y - envelopeHeight * 0.10
            )
        )
        wave.move(
            to: CGPoint(
                x: leftHand.x - envelopeHeight * 0.12,
                y: leftHand.y - envelopeHeight * 0.17
            )
        )
        wave.addLine(
            to: CGPoint(
                x: leftHand.x - envelopeHeight * 0.16,
                y: leftHand.y - envelopeHeight * 0.27
            )
        )
        context.stroke(
            wave,
            with: .color(Color.red.opacity(0.36)),
            style: StrokeStyle(
                lineWidth: max(1.2, envelopeHeight * 0.03),
                lineCap: .round
            )
        )
    }
}
