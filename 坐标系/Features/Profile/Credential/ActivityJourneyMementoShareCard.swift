//
//  ActivityJourneyMementoShareCard.swift
//  坐标系
//
//  纪念票分享图（9:16，朋友圈竖图；无履约条码）。
//

import SwiftUI

struct ActivityJourneyMementoShareCard: View {
    let model: ActivityJourneyCredentialModel
    let shareCaption: String

    private var face: PassFaceModel { model.face }
    private var foregroundColor: Color { WalletPassEventTicketAppearance.foregroundColor }
    private var labelColor: Color { WalletPassEventTicketAppearance.labelColor }

    var body: some View {
        VStack(spacing: 0) {
            shareHeader
            CredentialArtHero(
                scene: model.artScene,
                theme: model.artTheme,
                aspectRatio: 1.0
            )
            shareBody
            shareFooter
        }
        .frame(width: 390)
        .background(face.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .colorScheme(.dark)
    }

    private var shareHeader: some View {
        HStack(alignment: .top) {
            HStack(spacing: PlatformMetrics.minContentGap) {
                BrandCloverMark(size: 24)
                Text(ActivityJourneyCopy.brandName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(foregroundColor)
            }
            Spacer()
            if let headline = model.mementoHeadline ?? face.passKindTitle {
                Text(headline)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(foregroundColor.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.16), in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var shareBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let primary = face.primaryFields.first {
                Text(primary.value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let header = face.headerFields.first {
                HStack(spacing: PlatformMetrics.hairlineSpacing) {
                    if !header.label.isEmpty {
                        Text(header.label)
                            .foregroundStyle(foregroundColor)
                    }
                    if !header.value.isEmpty {
                        Text(header.value)
                            .foregroundStyle(labelColor)
                    }
                }
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
            }

            if let secondary = face.secondaryFields.first, !secondary.value.isEmpty {
                Label(secondary.value, systemImage: "mappin.and.ellipse")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(labelColor)
                    .lineLimit(2)
            }

            if let nickname = face.participantNickname?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !nickname.isEmpty {
                Text("参与者 \(nickname)")
                    .font(.footnote)
                    .foregroundStyle(labelColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var shareFooter: some View {
        VStack(spacing: 6) {
            Text(ActivityJourneyCopy.mementoShareFooter)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(foregroundColor)

            Text(shareCaption)
                .font(.caption2)
                .foregroundStyle(labelColor)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(face.backgroundColor.opacity(0.98))
    }
}
