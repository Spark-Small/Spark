// Module: SparkBuddy — Profile tab provider rows (application + gated earnings).

import SparkDesignSystem
import SwiftUI

/// Embeds as multiple `List` rows inside Profile; do not wrap in a single `.sparkFlatTabListRow()`.
public struct BuddyProfileProviderSection: View {
    @State private var viewModel: BuddyProviderHubViewModel
    private let coordinator: BuddyCoordinator

    public init(coordinator: BuddyCoordinator) {
        self.coordinator = coordinator
        _viewModel = State(initialValue: coordinator.makeProviderHubViewModel())
    }

    public var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                providerRow(
                    title: String(
                        localized: "buddy.profile.provider.title",
                        defaultValue: "陪玩认证",
                        comment: "Provider certification row"
                    ),
                    preview: String(
                        localized: "buddy.profile.provider.loading",
                        defaultValue: "加载中…",
                        comment: "Provider loading"
                    ),
                    systemImage: "person.badge.shield.checkmark"
                )
            case .failure(let message):
                providerRow(
                    title: String(
                        localized: "buddy.profile.provider.title",
                        defaultValue: "陪玩认证",
                        comment: "Provider certification row"
                    ),
                    preview: message,
                    systemImage: "person.badge.shield.checkmark"
                )
            case .loaded(let status):
                loadedRows(status: status)
            }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private func loadedRows(status: BuddyProviderStatus) -> some View {
        switch status.state {
        case .none, .rejected:
            NavigationLink {
                BuddyProviderApplicationView(viewModel: coordinator.makeProviderApplicationViewModel()) {
                    Task { await viewModel.reload() }
                }
            } label: {
                providerRow(
                    title: String(
                        localized: "buddy.profile.provider.apply.title",
                        defaultValue: "陪玩认证申请",
                        comment: "Apply as companion"
                    ),
                    preview: status.state == .rejected
                        ? (status.rejectionReason ?? status.localizedTitle)
                        : String(
                            localized: "buddy.profile.provider.apply.preview",
                            defaultValue: "提交资料，成为平台认证陪玩",
                            comment: "Apply preview"
                        ),
                    systemImage: "person.badge.plus"
                )
            }
            .simultaneousGesture(TapGesture().onEnded {
                BuddyTelemetry.providerApplicationOpened()
            })
        case .pending:
            providerRow(
                title: String(
                    localized: "buddy.profile.provider.pending.title",
                    defaultValue: "陪玩认证审核中",
                    comment: "Pending provider review"
                ),
                preview: String(
                    localized: "buddy.profile.provider.pending.preview",
                    defaultValue: "审核通过后可管理订单与收益",
                    comment: "Pending preview"
                ),
                systemImage: "clock.badge.checkmark"
            )
        case .approved:
            NavigationLink {
                BuddyProviderApplicationView(viewModel: coordinator.makeProviderApplicationViewModel()) {
                    Task { await viewModel.reload() }
                }
            } label: {
                providerRow(
                    title: String(
                        localized: "buddy.profile.provider.certified.title",
                        defaultValue: "陪玩认证",
                        comment: "Certified provider"
                    ),
                    preview: status.localizedTitle,
                    systemImage: "checkmark.seal.fill"
                )
            }
            NavigationLink {
                BuddyProviderEarningsView(viewModel: coordinator.makeProviderEarningsViewModel())
            } label: {
                providerRow(
                    title: String(
                        localized: "buddy.profile.provider.earnings.title",
                        defaultValue: "陪玩收益",
                        comment: "Companion earnings"
                    ),
                    preview: String(
                        localized: "buddy.profile.provider.earnings.preview",
                        defaultValue: "订单、托管结算与提现",
                        comment: "Earnings preview"
                    ),
                    systemImage: "yensign.circle.fill"
                )
            }
            .simultaneousGesture(TapGesture().onEnded {
                BuddyTelemetry.providerEarningsOpened()
            })
        case .suspended:
            providerRow(
                title: String(
                    localized: "buddy.profile.provider.suspended.title",
                    defaultValue: "陪玩服务已暂停",
                    comment: "Suspended provider"
                ),
                preview: status.rejectionReason ?? status.localizedTitle,
                systemImage: "exclamationmark.shield"
            )
        }
    }

    private func providerRow(title: String, preview: String, systemImage: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.inboxRowVerticalPadding)
        .frame(minHeight: SparkLayoutMetrics.inboxConversationRowMinHeight, alignment: .center)
        .accessibilityElement(children: .combine)
        .sparkFlatTabListRow()
    }
}

#Preview("Provider section") {
    NavigationStack {
        List {
            BuddyProfileProviderSection(coordinator: BuddyCoordinator(repository: MockBuddyRepository()))
                .sparkFlatTabListRow()
        }
        .sparkFlatTabListStyle()
    }
}
