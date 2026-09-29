//
//  BuddyCompanionServiceSKU.swift
//  坐标系
//
//  陪玩详情：服务 SKU、菜单与 Tab。
//

import SwiftUI
import CoordinateModels

// MARK: - Detail service SKUs / reviews

struct BuddyCompanionServiceSKU: Identifiable, Hashable {
    let id: String
    var title: String
    var detail: String
    var priceText: String
    var systemImage: String
    var isPrimary: Bool
    /// true：按天等议价项目，下单前双方私信对齐价格
    var isNegotiable: Bool = false
    var pricingUnit: CompanionPricingUnit? = nil
}

enum BuddyCompanionServiceMenu {
    static func skus(for companion: PaidCompanion) -> [BuddyCompanionServiceSKU] {
        var rows: [BuddyCompanionServiceSKU] = []

        switch companion.serviceType {
        case .voice:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: "语音连麦",
                    detail: "先连麦熟悉 · 可续时",
                    priceText: companion.priceText,
                    systemImage: "waveform",
                    isPrimary: true
                )
            )
            let hourPrice = max(companion.hourlyPrice * 2 - 10, companion.hourlyPrice + 15)
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "voice-hour",
                    title: "语音 1 小时",
                    detail: "深度聊天 / 开黑语音",
                    priceText: CompanionPricing.format(amount: hourPrice, unit: .hour),
                    systemImage: "mic.fill",
                    isPrimary: false
                )
            )
        case .sport:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: BuddyPaidMarketCatalog.shortSpecialty(companion.specialty),
                    detail: "1 对 1 陪练 · 按小时计费",
                    priceText: companion.priceText,
                    systemImage: companion.serviceType.systemImage,
                    isPrimary: true
                )
            )
            let pack3h = Int((Double(companion.hourlyPrice * 3) * 0.88).rounded())
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "pack-3h",
                    title: "3 小时套餐",
                    detail: "连续约满 3 小时享 88 折",
                    priceText: CompanionPricing.pack(amount: pack3h, label: "/3小时"),
                    systemImage: "clock.badge.checkmark",
                    isPrimary: false
                )
            )
            appendVoiceWarmup(to: &rows, companion: companion)
            appendDailyNegotiable(to: &rows, companion: companion)
        case .offline:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: "线下见面",
                    detail: "\(companion.specialty) · \(companion.profile.city) · 2 小时起约",
                    priceText: companion.priceText,
                    systemImage: companion.serviceType.systemImage,
                    isPrimary: true
                )
            )
            let halfDay = Int((Double(companion.hourlyPrice * 4) * 0.9).rounded())
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "half-day",
                    title: "半天陪伴",
                    detail: "约 4 小时 · 含见面等候",
                    priceText: CompanionPricing.pack(amount: halfDay, label: "/4小时"),
                    systemImage: "sun.max",
                    isPrimary: false
                )
            )
            appendVoiceWarmup(to: &rows, companion: companion)
            appendDailyNegotiable(to: &rows, companion: companion)
        case .photo:
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "primary",
                    title: "跟拍 1 小时",
                    detail: "\(companion.specialty) · 含机位建议",
                    priceText: companion.priceText,
                    systemImage: companion.serviceType.systemImage,
                    isPrimary: true
                )
            )
            let sessionPrice = max(companion.hourlyPrice + 28, 128)
            rows.append(
                BuddyCompanionServiceSKU(
                    id: "session",
                    title: "打卡套餐",
                    detail: "约 1.5 小时 · 精修 3 张",
                    priceText: CompanionPricing.format(amount: sessionPrice, unit: .session),
                    systemImage: "sparkles",
                    isPrimary: false
                )
            )
            appendVoiceWarmup(to: &rows, companion: companion)
            appendDailyNegotiable(to: &rows, companion: companion)
        }

        if companion.isAvailable {
            appendFirstOrderTrial(to: &rows, companion: companion)
        }
        return rows
    }

    private static func appendVoiceWarmup(to rows: inout [BuddyCompanionServiceSKU], companion: PaidCompanion) {
        let voicePrice = max(companion.hourlyPrice / 3, 19)
        rows.append(
            BuddyCompanionServiceSKU(
                id: "voice-warmup",
                title: "语音预热",
                detail: "见面 / 开练前先连麦对齐",
                priceText: CompanionPricing.format(amount: voicePrice, unit: .halfHour),
                systemImage: "waveform",
                isPrimary: false
            )
        )
    }

    private static func appendDailyNegotiable(to rows: inout [BuddyCompanionServiceSKU], companion: PaidCompanion) {
        rows.append(
            BuddyCompanionServiceSKU(
                id: "daily",
                title: "按天陪伴",
                detail: "全天档期 · 行程与费用双方私信商议后确认",
                priceText: CompanionPricing.negotiable,
                systemImage: "calendar.day.timeline.left",
                isPrimary: false,
                isNegotiable: true,
                pricingUnit: .day
            )
        )
    }

    private static func appendFirstOrderTrial(to rows: inout [BuddyCompanionServiceSKU], companion: PaidCompanion) {
        let trialPrice = max(Int((Double(companion.hourlyPrice) * 0.8).rounded()), 29)
        rows.append(
            BuddyCompanionServiceSKU(
                id: "trial",
                title: "首单体验",
                detail: "新客专享 · 限 1 次",
                priceText: CompanionPricing.format(amount: trialPrice, unit: companion.pricingUnit),
                systemImage: "gift",
                isPrimary: false
            )
        )
    }
}

struct BuddyCompanionServiceSKURow: View {
    let sku: BuddyCompanionServiceSKU
    var bookEnabled: Bool
    var onBook: () -> Void

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

    var body: some View {
        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
            Image(systemName: sku.systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(
                    width: chromeMeasurements.navigationBarButtonSide,
                    height: chromeMeasurements.navigationBarButtonSide
                )
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(sku.title)
                    .font(.body.weight(.semibold))
                Text(sku.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: PlatformMetrics.detailMicroSpacing) {
                Text(sku.priceText)
                    .font(sku.isNegotiable ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(sku.isNegotiable ? .secondary : PlatformStatus.warning)
                Button(sku.isNegotiable ? "约聊议价" : "下单", action: onBook)
                    .activityPrimaryCTA(controlSize: .regular)
                    .disabled(!bookEnabled)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

enum PaidCompanionDetailTab: String, CaseIterable, Identifiable {
    case profile = "资料"
    case service = "服务"
    case reviews = "评价"

    var id: String { rawValue }
}
