//
//  WalletCardChrome.swift
//  坐标系
//
//  钱包主卡：银行卡面等级（普卡 / 金 / 白金 / 黑卡 / 彩色），
//  卡号为用户 UUID，右下角为昵称。
//

import SwiftUI

/// 累计充值对应的银行卡面等级
enum WalletBankCardTier: String, CaseIterable, Comparable {
    case classic
    case gold
    case platinum
    case black
    case spectrum

    var rank: Int {
        switch self {
        case .classic: 0
        case .gold: 1
        case .platinum: 2
        case .black: 3
        case .spectrum: 4
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }

    /// 累计充值（分）门槛，含开户赠送
    static func resolve(lifetimeTopUpCents: Int) -> Self {
        switch lifetimeTopUpCents {
        case ..<80_000: .classic      // < ¥800
        case ..<300_000: .gold       // < ¥3,000
        case ..<1_000_000: .platinum // < ¥10,000
        case ..<3_000_000: .black    // < ¥30,000
        default: .spectrum           // 彩色卡面
        }
    }

    var displayName: String {
        switch self {
        case .classic: "普卡"
        case .gold: "金卡"
        case .platinum: "白金卡"
        case .black: "黑卡"
        case .spectrum: "多彩卡"
        }
    }

    var englishName: String {
        switch self {
        case .classic: "Classic"
        case .gold: "Gold"
        case .platinum: "Platinum"
        case .black: "Black"
        case .spectrum: "Spectrum"
        }
    }

    /// 下一档提示；已是最高档返回 nil
    var nextTierHint: String? {
        switch self {
        case .classic: "再充值可升级金卡"
        case .gold: "再充值可升级白金卡"
        case .platinum: "再充值可升级黑卡"
        case .black: "再充值可解锁多彩卡"
        case .spectrum: nil
        }
    }
}

enum WalletCardNumberFormatting {
    /// UUID → 银行卡号单行（取前 16 位十六进制，四组空格，形如 `A1B2 C3D4 E5F6 7890`）
    static func display(from userID: UUID) -> String {
        let hex = userID.uuidString
            .replacingOccurrences(of: "-", with: "")
            .uppercased()
        let pan = String(hex.prefix(16))
        var groups: [String] = []
        var index = pan.startIndex
        while index < pan.endIndex {
            let end = pan.index(index, offsetBy: 4, limitedBy: pan.endIndex) ?? pan.endIndex
            groups.append(String(pan[index..<end]))
            index = end
        }
        return groups.joined(separator: " ")
    }
}

struct WalletBankBalanceCard: View {
    let balanceText: String
    let tier: WalletBankCardTier
    let userID: UUID
    let nickname: String
    var isMember: Bool = false
    var onTopUp: (() -> Void)?

    /// ISO/IEC 7810 ID-1：85.60 × 53.98 mm
    private static let bankCardAspectRatio: CGFloat = 85.60 / 53.98
    /// 实体卡圆角 ≈ 3.18 mm / 卡宽 85.60 mm（圆形弧，非 continuous squircle）
    private static let cornerRadiusRatio: CGFloat = 3.18 / 85.60
    /// 卡面内边距 ≈ 实体卡印刷边距比例
    private static let contentInsetRatio: CGFloat = 0.055

    private var cardNumber: String { WalletCardNumberFormatting.display(from: userID) }

    var body: some View {
        Button(action: { onTopUp?() }) {
            Color.clear
                .aspectRatio(Self.bankCardAspectRatio, contentMode: .fit)
                .overlay {
                    GeometryReader { geo in
                        let radius = max(10, geo.size.width * Self.cornerRadiusRatio)
                        let inset = max(14, geo.size.width * Self.contentInsetRatio)
                        let shape = RoundedRectangle(cornerRadius: radius, style: .circular)

                        cardFace(chipWidth: geo.size.width * 0.118)
                            .padding(inset)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                            .background { cardBackground }
                            .clipShape(shape)
                            .overlay {
                                shape.strokeBorder(palette.stroke, lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(onTopUp == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(tier.displayName)钱包卡，余额 \(balanceText)，持卡人 \(nickname)，卡号 \(userID.uuidString)"
            + (isMember ? "，会员" : "")
        )
        .accessibilityHint("轻点充值")
        .accessibilityAddTraits(onTopUp == nil ? [] : .isButton)
    }

    private func cardFace(chipWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("坐标系")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                Spacer(minLength: 0)
                if isMember {
                    Label("会员", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(palette.secondaryLabel)
                        .labelStyle(.titleAndIcon)
                } else {
                    Text(tier.englishName.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(palette.secondaryLabel)
                }
            }

            Spacer(minLength: 8)

            HStack(alignment: .center, spacing: 10) {
                WalletBankCardChip(width: chipWidth)
                Image(systemName: "wave.3.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(palette.secondaryLabel)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
            }

            Spacer(minLength: 8)

            Text(cardNumber)
                .font(.title3.monospaced().weight(.semibold))
                .foregroundStyle(palette.primaryLabel)
                .tracking(1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("可用余额")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(palette.secondaryLabel)
                    Text(balanceText)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(palette.primaryLabel)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("持卡人")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(palette.secondaryLabel)
                    Text(nickname)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.primaryLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch tier {
        case .classic:
            LinearGradient(
                colors: [Color(white: 0.42), Color(white: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.79, blue: 0.45),
                    Color(red: 0.72, green: 0.52, blue: 0.18),
                    Color(red: 0.45, green: 0.32, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .platinum:
            LinearGradient(
                colors: [
                    Color(white: 0.92),
                    Color(white: 0.72),
                    Color(white: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .black:
            LinearGradient(
                colors: [Color(white: 0.18), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .spectrum:
            // 苹果 Wallet 式多彩卡面
            AngularGradient(
                colors: [
                    Color(red: 1.0, green: 0.35, blue: 0.45),
                    Color(red: 1.0, green: 0.65, blue: 0.20),
                    Color(red: 0.35, green: 0.85, blue: 0.55),
                    Color(red: 0.25, green: 0.55, blue: 1.0),
                    Color(red: 0.65, green: 0.35, blue: 0.95),
                    Color(red: 1.0, green: 0.35, blue: 0.45)
                ],
                center: .center,
                startAngle: .degrees(-40),
                endAngle: .degrees(320)
            )
            .overlay {
                LinearGradient(
                    colors: [
                        .black.opacity(0.15),
                        .black.opacity(0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var palette: WalletCardPalette {
        switch tier {
        case .classic, .black, .spectrum:
            WalletCardPalette(
                primaryLabel: .white,
                secondaryLabel: .white.opacity(0.75),
                stroke: .white.opacity(0.18),
                buttonTint: .white.opacity(0.22),
                buttonLabel: .white
            )
        case .gold:
            WalletCardPalette(
                primaryLabel: Color(red: 0.18, green: 0.12, blue: 0.05),
                secondaryLabel: Color(red: 0.28, green: 0.18, blue: 0.08).opacity(0.85),
                stroke: .white.opacity(0.25),
                buttonTint: Color(red: 0.25, green: 0.16, blue: 0.06).opacity(0.85),
                buttonLabel: Color(red: 0.98, green: 0.92, blue: 0.75)
            )
        case .platinum:
            WalletCardPalette(
                primaryLabel: Color(white: 0.12),
                secondaryLabel: Color(white: 0.28),
                stroke: Color(white: 0.55).opacity(0.5),
                buttonTint: Color(white: 0.2),
                buttonLabel: .white
            )
        }
    }
}

/// EMV 芯片示意（金属渐变小块）
private struct WalletBankCardChip: View {
    var width: CGFloat

    var body: some View {
        let height = width * 0.72
        let radius = max(2, width * 0.12)
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.82, blue: 0.48),
                        Color(red: 0.72, green: 0.58, blue: 0.28),
                        Color(red: 0.88, green: 0.76, blue: 0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
            }
            .overlay {
                // 触点分隔线
                VStack(spacing: height * 0.18) {
                    chipContactLine
                    chipContactLine
                }
                .padding(.horizontal, width * 0.14)
            }
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }

    private var chipContactLine: some View {
        Rectangle()
            .fill(Color.black.opacity(0.12))
            .frame(height: 1)
    }
}

private struct WalletCardPalette {
    let primaryLabel: Color
    let secondaryLabel: Color
    let stroke: Color
    let buttonTint: Color
    let buttonLabel: Color
}
