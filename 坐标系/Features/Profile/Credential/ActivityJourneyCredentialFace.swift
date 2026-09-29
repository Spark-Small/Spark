//
//  ActivityJourneyCredentialFace.swift
//  坐标系
//
//  App 内活动凭证票面：header · hero 彩绘 · 字段 · 可选条码。
//

import SwiftUI

private enum ActivityJourneyCredentialChrome {
    static var horizontal: CGFloat { WalletPassChromePadding.horizontal }
    static var vertical: CGFloat { WalletPassChromePadding.vertical }
    static var fieldSpacing: CGFloat { WalletPassChromePadding.stackSpacing }

    static var sectionInsets: EdgeInsets {
        EdgeInsets(
            top: vertical,
            leading: horizontal,
            bottom: vertical,
            trailing: horizontal
        )
    }
}

struct ActivityJourneyCredentialFace: View {
    let model: ActivityJourneyCredentialModel
    /// 履约态票面下沿的轻量旅程进度；纪念态 / 作废态不传。
    var progressRows: [ActivityJourneyTimelineRow] = []

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.platformChromeMeasurements) private var chromeMeasurements
    @ScaledMetric(relativeTo: .body) private var brandMarkSide = 22

    private var face: PassFaceModel { model.face }
    private var foregroundColor: Color { WalletPassEventTicketAppearance.foregroundColor }
    private var labelColor: Color { WalletPassEventTicketAppearance.labelColor }

    private var trimmedPassKindTitle: String? {
        if model.presentation == .memento,
           let headline = model.mementoHeadline?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !headline.isEmpty {
            return headline
        }
        guard let kind = face.passKindTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !kind.isEmpty
        else { return nil }
        return kind
    }

    private let auxiliaryColumns = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(), alignment: .leading)
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            CredentialArtHero(
                scene: model.artScene,
                theme: model.artTheme,
                aspectRatio: model.presentation == .memento ? 375.0 / 140.0 : 375.0 / 120.0
            )
            fieldBody
            if model.showsBarcode {
                barcodeSection
            } else if model.presentation == .memento,
                      let headline = model.mementoHeadline?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                      !headline.isEmpty {
                mementoFooter(headline)
            }

            if !progressRows.isEmpty {
                ActivityJourneyPassProgressStrip(rows: progressRows)
            }
        }
        .frame(maxWidth: .infinity)
        .background(face.backgroundColor)
        .clipShape(PlatformMetrics.walletPassFaceShape)
        .overlay {
            PlatformMetrics.walletPassFaceShape
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .overlay {
            if face.voided {
                ActivityJourneyPassVoidedOverlay()
            }
        }
        .colorScheme(.dark)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.accessibilitySummary)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top, spacing: PlatformMetrics.cardInfoSpacing) {
            VStack(alignment: .leading, spacing: ActivityJourneyCredentialChrome.fieldSpacing) {
                HStack(spacing: PlatformMetrics.minContentGap) {
                    BrandCloverMark(size: brandMarkSide)
                    Text(face.logoText)
                        .font(WalletPassTypography.logoMeta.weight(.semibold))
                        .foregroundStyle(foregroundColor)
                        .lineLimit(WalletPassAccessibility.participantLineLimit(for: dynamicTypeSize))
                }

                if let nickname = face.participantNickname?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !nickname.isEmpty {
                    inlineMetaLine(label: "参与者", value: nickname)
                        .accessibilityLabel("参与者 \(nickname)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let header = face.headerFields.first {
                scheduleColumn(header)
            }
        }
        .padding(ActivityJourneyCredentialChrome.sectionInsets)
    }

    private func scheduleColumn(_ header: PassField) -> some View {
        VStack(alignment: .trailing, spacing: PlatformMetrics.sectionSubtitleSpacing) {
            if !header.label.isEmpty {
                Text(header.label)
                    .font(WalletPassTypography.headerLabel)
                    .foregroundStyle(foregroundColor)
                    .lineLimit(WalletPassAccessibility.scheduleLineLimit(for: dynamicTypeSize))
                    .multilineTextAlignment(.trailing)
            }
            if !header.value.isEmpty {
                Text(header.value)
                    .font(WalletPassTypography.headerValue)
                    .foregroundStyle(labelColor)
                    .lineLimit(WalletPassAccessibility.scheduleLineLimit(for: dynamicTypeSize))
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func inlineMetaLine(label: String, value: String) -> some View {
        HStack(spacing: PlatformMetrics.hairlineSpacing) {
            Text(label)
            Text(value)
        }
        .font(WalletPassTypography.headerValue)
        .foregroundStyle(labelColor)
        .lineLimit(WalletPassAccessibility.scheduleLineLimit(for: dynamicTypeSize))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Fields

    private var fieldBody: some View {
        VStack(alignment: .leading, spacing: ActivityJourneyCredentialChrome.fieldSpacing) {
            primarySection

            ForEach(face.primaryFields.dropFirst(), id: \.key) { field in
                passFieldBlock(
                    field,
                    valueFont: WalletPassTypography.primaryFieldValue,
                    valueLineLimit: WalletPassAccessibility.heroValueLineLimit(for: dynamicTypeSize)
                )
            }

            ForEach(face.secondaryFields, id: \.key) { field in
                passFieldBlock(
                    field,
                    valueFont: WalletPassTypography.fieldValue,
                    valueLineLimit: WalletPassAccessibility.fieldValueLineLimit(
                        for: dynamicTypeSize,
                        primary: false
                    )
                )
            }

            if !face.auxiliaryFields.isEmpty {
                LazyVGrid(
                    columns: auxiliaryColumns,
                    alignment: .leading,
                    spacing: ActivityJourneyCredentialChrome.fieldSpacing
                ) {
                    ForEach(face.auxiliaryFields, id: \.key) { field in
                        passFieldBlock(
                            field,
                            valueFont: WalletPassTypography.fieldValue,
                            valueLineLimit: WalletPassAccessibility.fieldValueLineLimit(
                                for: dynamicTypeSize,
                                primary: false
                            )
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ActivityJourneyCredentialChrome.sectionInsets)
    }

    private var primarySection: some View {
        HStack(alignment: .top, spacing: PlatformMetrics.cardInfoSpacing) {
            if let primary = face.primaryFields.first {
                passFieldBlock(
                    primary,
                    valueFont: WalletPassTypography.primaryFieldValue,
                    valueLineLimit: WalletPassAccessibility.heroValueLineLimit(for: dynamicTypeSize)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let badge = trimmedPassKindTitle {
                credentialBadge(badge)
            }
        }
    }

    private func credentialBadge(_ title: String) -> some View {
        Text(title)
            .font(WalletPassTypography.kindBadge)
            .foregroundStyle(foregroundColor.opacity(0.92))
            .padding(.horizontal, PlatformMetrics.hairlineSpacing * 2)
            .padding(.vertical, PlatformMetrics.hairlineSpacing)
            .background(.white.opacity(model.presentation == .memento ? 0.2 : 0.14), in: Capsule())
            .lineLimit(WalletPassAccessibility.kindBadgeLineLimit(for: dynamicTypeSize))
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(title)
    }

    private func passFieldBlock(
        _ field: PassField,
        valueFont: Font,
        valueLineLimit: Int?
    ) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            if !field.label.isEmpty {
                Text(field.label)
                    .font(WalletPassTypography.fieldLabel)
                    .foregroundStyle(labelColor)
                    .lineLimit(WalletPassAccessibility.fieldLabelLineLimit(for: dynamicTypeSize))
            }
            fieldValueText(field, font: valueFont, lineLimit: valueLineLimit)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func fieldValueText(_ field: PassField, font: Font, lineLimit: Int?) -> some View {
        let text = Text(field.value)
            .font(font)
            .foregroundStyle(foregroundColor)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

        if PassFaceFieldFormatting.usesMonospacedDigits(key: field.key) {
            text.monospacedDigit()
        } else {
            text
        }
    }

    // MARK: - Footer

    private func mementoFooter(_ headline: String) -> some View {
        Text("\(headline) · \(ActivityJourneyCopy.mementoShareFooter)")
            .font(WalletPassTypography.headerValue)
            .foregroundStyle(labelColor)
            .multilineTextAlignment(.center)
            .lineLimit(WalletPassAccessibility.participantLineLimit(for: dynamicTypeSize))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(ActivityJourneyCredentialChrome.sectionInsets)
            .accessibilityLabel("\(headline)，\(ActivityJourneyCopy.mementoShareFooter)")
    }

    private var barcodeSection: some View {
        VStack(spacing: 0) {
            WalletPassBarcodeView(
                kind: .code128,
                message: face.barcodeMessage,
                fillsBounds: true
            )
            .frame(maxWidth: .infinity)
            .frame(height: PlatformMetrics.walletPassFooterBandHeight(
                navigationBarButtonSide: chromeMeasurements.navigationBarButtonSide
            ))
            .clipped()
            .accessibilityLabel("活动凭证码")
            .accessibilityValue(face.barcodeMessage)

            if model.showsOrderNumber,
               let orderNumber = face.orderNumber?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !orderNumber.isEmpty {
                Text("订单编号 \(orderNumber)")
                    .font(WalletPassTypography.headerValue)
                    .foregroundStyle(labelColor)
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .lineLimit(WalletPassAccessibility.participantLineLimit(for: dynamicTypeSize))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(ActivityJourneyCredentialChrome.sectionInsets)
                    .accessibilityLabel("订单编号 \(orderNumber)")
            }
        }
    }
}

// MARK: - Pass progress strip

/// 票面下沿：当前步骤 + 圆点进度 + 完成数（登机口信息条风格）。
private struct ActivityJourneyPassProgressStrip: View {
    let rows: [ActivityJourneyTimelineRow]

    private var completedCount: Int { rows.filter(\.isComplete).count }
    private var currentTitle: String {
        rows.first(where: \.isCurrent)?.step.title ?? ""
    }

    var body: some View {
        HStack(spacing: PlatformMetrics.minContentGap) {
            Text(currentTitle)
                .font(WalletPassTypography.headerValue.weight(.semibold))
                .foregroundStyle(WalletPassEventTicketAppearance.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: PlatformMetrics.minContentGap)

            HStack(spacing: 5) {
                ForEach(rows) { row in
                    Circle()
                        .fill(dotColor(for: row))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)

            Text("\(completedCount)/\(rows.count)")
                .font(WalletPassTypography.headerValue.monospacedDigit().weight(.medium))
                .foregroundStyle(WalletPassEventTicketAppearance.foregroundColor.opacity(0.88))
        }
        .padding(.horizontal, ActivityJourneyCredentialChrome.horizontal)
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding * 0.65)
        .background {
            Rectangle().fill(Color.white.opacity(0.06))
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(ActivityJourneyCopy.progressAccessibility(rows: rows))
    }

    private func dotColor(for row: ActivityJourneyTimelineRow) -> Color {
        if row.isComplete { return PlatformStatus.success }
        if row.isCurrent { return WalletPassEventTicketAppearance.foregroundColor }
        return WalletPassEventTicketAppearance.labelColor.opacity(0.45)
    }
}
