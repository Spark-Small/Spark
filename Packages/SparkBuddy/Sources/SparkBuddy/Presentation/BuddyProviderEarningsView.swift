// Module: SparkBuddy — Approved companion earnings dashboard (gated).

import SparkDesignSystem
import SwiftUI

public struct BuddyProviderEarningsView: View {
    @State private var viewModel: BuddyProviderEarningsViewModel

    public init(viewModel: BuddyProviderEarningsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "buddy.provider.earnings.error.title",
                        defaultValue: "无法加载收益",
                        comment: "Earnings error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.load() }
                }
            case .loaded(let earnings, let orders):
                List {
                    Section {
                        earningsMetric(
                            title: String(
                                localized: "buddy.provider.earnings.available",
                                defaultValue: "可提现",
                                comment: "Available balance"
                            ),
                            amount: earnings.availableBalance,
                            currencyCode: earnings.currencyCode
                        )
                        earningsMetric(
                            title: String(
                                localized: "buddy.provider.earnings.escrow",
                                defaultValue: "托管中",
                                comment: "Escrow pending"
                            ),
                            amount: earnings.pendingEscrow,
                            currencyCode: earnings.currencyCode
                        )
                        earningsMetric(
                            title: String(
                                localized: "buddy.provider.earnings.month",
                                defaultValue: "本月收入",
                                comment: "Month earnings"
                            ),
                            amount: earnings.monthEarnings,
                            currencyCode: earnings.currencyCode
                        )
                    } header: {
                        Text(
                            String(
                                localized: "buddy.provider.earnings.summary",
                                defaultValue: "收益概览",
                                comment: "Earnings summary"
                            )
                        )
                    } footer: {
                        Text(
                            String(
                                localized: "buddy.provider.earnings.footer",
                                defaultValue: "仅认证通过的陪玩可查看收益与订单。",
                                comment: "Earnings gate footer"
                            )
                        )
                    }
                    Section {
                        ForEach(orders) { order in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(order.guestDisplayName)
                                        .font(.body.weight(.semibold))
                                    Spacer()
                                    Text(order.state.localizedTitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Text(order.packageTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(
                                    BuddyFormatting.packagePriceLine(
                                        amount: order.amount,
                                        currencyCode: order.currencyCode
                                    )
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text(
                            String(
                                localized: "buddy.provider.orders.title",
                                defaultValue: "接单管理",
                                comment: "Provider orders"
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle(
            String(localized: "buddy.provider.earnings.title", defaultValue: "陪玩收益", comment: "Earnings title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onAppear { BuddyTelemetry.providerEarningsOpened() }
    }

    private func earningsMetric(title: String, amount: Decimal, currencyCode: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(BuddyFormatting.packagePriceLine(amount: amount, currencyCode: currencyCode))
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
    }
}

#Preview {
    NavigationStack {
        BuddyProviderEarningsView(
            viewModel: BuddyProviderEarningsViewModel(
                fetchEarnings: FetchBuddyProviderEarningsUseCase(repository: MockBuddyRepository()),
                fetchOrders: FetchBuddyProviderOrdersUseCase(repository: MockBuddyRepository())
            )
        )
    }
}
