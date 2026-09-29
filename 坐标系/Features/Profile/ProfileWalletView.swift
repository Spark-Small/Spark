//
//  ProfileWalletView.swift
//  坐标系
//
//  钱包余额与流水。
//

import CoordinateModels
import SwiftUI

struct ProfileWalletView: View {
    @Environment(WalletStore.self) private var wallet
    @Environment(AppModel.self) private var app
    @Environment(MembershipStore.self) private var membership
    @State private var showTopUp = false
    @State private var showCreateAccount = false
    @State private var demoAlertMessage: String?

    private var tier: WalletBankCardTier { wallet.cardTier }

    var body: some View {
        Form {
            if app.auth.isGuest {
                Section {
                    Text(GuestAccessGate.commerceReason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("创建账号后使用钱包") {
                        showCreateAccount = true
                    }
                    .fontWeight(.semibold)
                }
            }

            Section {
                WalletBankBalanceCard(
                    balanceText: wallet.balanceText,
                    tier: tier,
                    userID: app.user.id,
                    nickname: app.user.name,
                    isMember: membership.isEntitled,
                    onTopUp: {
                        if app.auth.isGuest {
                            showCreateAccount = true
                        } else if !YouthModePreference.isEnabled {
                            showTopUp = true
                        }
                    }
                )
                .listRowInsets(PlatformWalletPassListRow.insets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } footer: {
                if let hint = tier.nextTierHint {
                    Text("当前\(tier.displayName) · 累计充值 \(WalletMoney.formatted(cents: wallet.lifetimeTopUpCents)) · \(hint)")
                } else {
                    Text("当前\(tier.displayName) · 累计充值 \(WalletMoney.formatted(cents: wallet.lifetimeTopUpCents)) · 已达最高卡面")
                }
            }

            Section {
                LabeledContent(ProfileDashboardCopy.walletCoupons, value: "\(wallet.couponCount)")
                LabeledContent(ProfileDashboardCopy.walletPoints, value: "\(wallet.points)")
            } header: {
                Text("资产")
            }

            Section {
                Button {
                    openWalletAction { showTopUp = true }
                } label: {
                    Label(ProfileDashboardCopy.walletTopUp, systemImage: "plus.circle.fill")
                        .platformContentSymbolStyle()
                }
                .disabled(YouthModePreference.isEnabled)

                Button {
                    demoAlertMessage = ProfileDashboardCopy.demoWithdraw
                } label: {
                    Label(ProfileDashboardCopy.walletWithdraw, systemImage: "arrow.down.circle.fill")
                        .platformContentSymbolStyle()
                }

                Button {
                    demoAlertMessage = ProfileDashboardCopy.demoInvoice
                } label: {
                    Label(ProfileDashboardCopy.walletInvoice, systemImage: "doc.text.fill")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text("快捷操作")
            } footer: {
                if YouthModePreference.isEnabled {
                    Text(GuestAccessGate.youthCommerceReason)
                } else {
                    Text("充值即时入账；提现与发票为本地演示占位，正式版将接入实名与开票。")
                }
            }

            Section {
                LabeledContent {
                    Text(PaymentMethod.wallet.displayName)
                } label: {
                    Label("默认支付", systemImage: "creditcard")
                        .platformContentSymbolStyle()
                }
                LabeledContent {
                    Text(tier.displayName)
                } label: {
                    Label("卡面等级", systemImage: "rectangle.on.rectangle.angled")
                        .platformContentSymbolStyle()
                }
                LabeledContent {
                    Text(membership.isEntitled ? "已开通" : "未开通")
                        .foregroundStyle(membership.isEntitled ? PlatformStatus.success : .secondary)
                } label: {
                    Label("会员", systemImage: "checkmark.seal")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text("支付设置")
            } footer: {
                Text("订单在「我的」首页「我的订单」查看；活动票与陪玩预约凭证在「我的活动」区。点银行卡面可充值。")
            }

            Section {
                if wallet.entries.isEmpty {
                    Text("暂无交易")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(wallet.entries) { entry in
                        WalletLedgerRow(entry: entry)
                    }
                }
            } header: {
                Text(ProfileDashboardCopy.walletLedger)
            } footer: {
                Text("活动、陪玩与转账共用同一套本地支付账本。")
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("我的钱包")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("充值", systemImage: "plus") {
                    openWalletAction { showTopUp = true }
                }
                .disabled(YouthModePreference.isEnabled)
            }
        }
        .animation(.snappy, value: wallet.balanceCents)
        .animation(.snappy, value: tier)
        .sheet(isPresented: $showTopUp) {
            WalletTopUpSheet()
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showCreateAccount) {
            ProfileCreateAccountSheet(
                session: app.auth,
                reason: GuestAccessGate.commerceReason
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert("提示", isPresented: Binding(
            get: { demoAlertMessage != nil },
            set: { if !$0 { demoAlertMessage = nil } }
        )) {
            Button("好的", role: .cancel) { demoAlertMessage = nil }
        } message: {
            Text(demoAlertMessage ?? "")
        }
    }

    private func openWalletAction(_ action: () -> Void) {
        if YouthModePreference.isEnabled { return }
        if GuestAccessGate.allow(app.auth, presentCreateAccount: $showCreateAccount) {
            action()
        }
    }
}

/// Form 行内流水：系统 Label + 金额强调
struct WalletLedgerRow: View {
    let entry: WalletLedgerEntry

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            Image(systemName: entry.kind.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(
                    width: chromeMeasurements.navigationBarButtonSide * 0.7,
                    alignment: .center
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(entry.title)
                    .font(.body)
                Text(secondaryLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: PlatformMetrics.minContentGap)

            Text(amountText)
                .font(.body.weight(.semibold))
                .foregroundStyle(amountColor)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var secondaryLine: String {
        var parts = [entry.method.displayName]
        if let subtitle = entry.subtitle,
           !subtitle.isEmpty,
           subtitle != WalletMoney.formatted(cents: entry.amountCents) {
            parts.append(subtitle)
        }
        parts.append(Formatters.conversationListTime(from: entry.createdAt))
        return parts.joined(separator: " · ")
    }

    private var amountText: String {
        if entry.balanceDeltaCents != 0 {
            return WalletMoney.signedFormatted(cents: entry.balanceDeltaCents)
        }
        return "-\(WalletMoney.formatted(cents: entry.amountCents))"
    }

    private var amountColor: Color {
        entry.balanceDeltaCents > 0 ? PlatformStatus.success : .primary
    }

    private var iconColor: Color {
        entry.balanceDeltaCents > 0 ? PlatformStatus.success : Color.accentColor
    }
}

