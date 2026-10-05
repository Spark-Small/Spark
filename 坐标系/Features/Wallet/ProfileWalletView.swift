//
//  ProfileWalletView.swift
//  坐标系
//
//  「我的钱包」：数字卡 + 账户 + 最近几条交易；全部流水进二级（按月/搜索）。
//

import CoordinateModels
import SwiftUI

struct ProfileWalletView: View {
    /// 首屏只留最近几条；完整流水走「查看全部」。
    private static let recentLimit = 3

    @Environment(WalletStore.self) private var wallet
    @Environment(AppModel.self) private var app
    @State private var showTopUp = false

    private var tier: WalletBankCardTier { wallet.cardTier }

    private var recentEntries: [WalletLedgerEntry] {
        Array(wallet.entries.prefix(Self.recentLimit))
    }

    private var canTopUp: Bool {
        !YouthModePreference.isEnabled && CommercePaymentPolicy.canAttemptTopUp
    }

    var body: some View {
        List {
            Section {
                WalletPaymentCardFace(
                    balanceText: wallet.balanceText,
                    tier: tier,
                    brandTitle: ProfileWalletCopy.cardBrand,
                    balanceLabel: ProfileWalletCopy.availableBalance,
                    holderName: app.user.name,
                    productMark: ProfileWalletCopy.cardProductMark,
                    accountCaption: ProfileWalletCopy.cardAccountCaption,
                    tapHint: ProfileWalletCopy.cardTapHint,
                    onTap: canTopUp ? { openTopUp() } : nil
                )
                .profileGroupedFullBleedRowChrome()
            }

            accountSection
            recentSection
        }
        .profileSecondaryListChrome(flushTop: true)
        .navigationTitle(ProfileWalletCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(ProfileDashboardCopy.walletTopUp) {
                    openTopUp()
                }
                .disabled(!canTopUp)
                .platformNavigationBarItemChrome()
            }
        }
        .animation(.snappy, value: wallet.balanceCents)
        .animation(.snappy, value: tier)
        .task {
            await wallet.refreshFromRemoteIfEnabled()
        }
        .refreshable {
            await wallet.refreshFromRemoteIfEnabled()
        }
        .sheet(isPresented: $showTopUp) {
            WalletTopUpSheet()
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        Section {
            if wallet.entries.isEmpty {
                ContentUnavailableView {
                    Label(ProfileWalletCopy.ledgerEmptyTitle, systemImage: "list.bullet.rectangle")
                } description: {
                    Text(ProfileWalletCopy.ledgerEmptyDescription)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(recentEntries) { entry in
                    WalletLedgerRow(entry: entry)
                }
                NavigationLink {
                    ProfileWalletLedgerAllView()
                } label: {
                    Label(ProfileWalletCopy.seeAllLedger, systemImage: "list.bullet.rectangle")
                        .platformContentSymbolStyle()
                }
            }
        } header: {
            Text(ProfileWalletCopy.recentSection)
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section {
            LabeledContent {
                Text(PaymentMethod.wallet.displayName)
            } label: {
                Label(ProfileWalletCopy.defaultPayment, systemImage: "wallet.bifold.fill")
                    .platformContentSymbolStyle()
            }

            LabeledContent {
                Text(tier.displayName)
            } label: {
                Label(ProfileWalletCopy.lifetimeTier, systemImage: "crown.fill")
                    .platformContentSymbolStyle()
            }
        } header: {
            Text(ProfileWalletCopy.accountSection)
        }
    }

    private func openTopUp() {
        guard canTopUp else { return }
        showTopUp = true
    }
}
