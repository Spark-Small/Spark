//
//  WalletPaymentCardFace.swift
//  坐标系
//
//  App 内余额数字卡：宽与 insetGrouped Form 同列；卡面用 WalletCardArt + 轻遮罩
// （非系统 Wallet 真卡 / 无 Visa / 无假 PAN）。
//

import SwiftUI

struct WalletPaymentCardFace: View {
    let balanceText: String
    let tier: WalletBankCardTier
    var brandTitle: String = "坐标系"
    var balanceLabel: String = "可用余额"
    /// 右下持卡人昵称
    var holderName: String = ""
    var productMark: String = "钱包"
    /// 左下账户说明（勿用掩码卡号样式）
    var accountCaption: String = "账户"
    var tapHint: String = "轻点充值"
    var onTap: (() -> Void)?

    /// ISO/IEC 7810 ID-1；宽度由 List 内容列决定
    private static let paymentCardAspectRatio: CGFloat = 85.60 / 53.98

    private var displayHolder: String {
        let trimmed = holderName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? brandTitle : trimmed
    }

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { card }
                    .buttonStyle(.plain)
            } else {
                card
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(tier.displayName)余额卡，\(balanceLabel) \(balanceText)，\(accountCaption)，持卡人 \(displayHolder)"
        )
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
        .accessibilityHint(onTap == nil ? "" : tapHint)
    }

    private var card: some View {
        cardFace
            .padding(PlatformMetrics.sectionSpacing)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background { cardArt }
            .clipShape(PlatformMetrics.cardShape)
            .contentShape(PlatformMetrics.cardShape)
            .aspectRatio(Self.paymentCardAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
    }

    /// Wallet store-card 场：品牌左、余额 header 右上；底栏账户说明 + 昵称。
    private var cardFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                    Text(brandTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(tier.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer(minLength: PlatformMetrics.cardInfoSpacing)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(balanceLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                    Text(balanceText)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.28), radius: 2, y: 1)
                }
                .accessibilityElement(children: .combine)
            }

            Spacer(minLength: 0)

            HStack(alignment: .bottom) {
                Text(accountCaption)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: PlatformMetrics.hairlineSpacing) {
                    Text(productMark)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(displayHolder)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
    }

    private var cardArt: some View {
        ZStack {
            tier.fallbackFill

            Image(tier.cardArtAssetName)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.28),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
