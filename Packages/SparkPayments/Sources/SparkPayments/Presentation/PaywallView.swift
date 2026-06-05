// Module: SparkPayments — StoreKit 2 paywall (products, purchase, restore).

import SwiftUI

public struct PaywallView: View {
    @Bindable var entitlementManager: EntitlementManager
    let placement: PaywallPlacement
    let onDismiss: () -> Void

    public init(
        entitlementManager: EntitlementManager,
        placement: PaywallPlacement,
        onDismiss: @escaping () -> Void
    ) {
        self.entitlementManager = entitlementManager
        self.placement = placement
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            List {
                if entitlementManager.hasPremium {
                    subscribedSection
                } else {
                    benefitsSection
                    productsSection
                    restoreSection
                }
                if let message = entitlementManager.lastErrorMessage {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(
                String(localized: "paywall.nav", defaultValue: "订阅", comment: "Paywall nav")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        String(localized: "paywall.close", defaultValue: "关闭", comment: "Close"),
                        action: onDismiss
                    )
                }
            }
            .task {
                await entitlementManager.refresh()
            }
        }
    }

    private var subscribedSection: some View {
        Section {
            Label(
                String(localized: "paywall.active", defaultValue: "已订阅", comment: "Subscribed"),
                systemImage: "checkmark.seal.fill"
            )
            .foregroundStyle(.green)
        } footer: {
            Text(
                String(
                    localized: "paywall.active.footer",
                    defaultValue: "感谢支持 Spark。",
                    comment: "Subscribed footer"
                )
            )
        }
    }

    private var benefitsSection: some View {
        Section {
            Text(
                String(
                    localized: "paywall.headline",
                    defaultValue: "解锁全部活动与消息能力",
                    comment: "Paywall headline"
                )
            )
            .font(.headline)
            Label(
                String(localized: "paywall.benefit.messages", defaultValue: "更多消息能力", comment: "Benefit"),
                systemImage: "message.fill"
            )
            Label(
                String(localized: "paywall.benefit.priority", defaultValue: "优先推荐", comment: "Benefit"),
                systemImage: "sparkles"
            )
        } footer: {
            Text(placementFooter)
        }
    }

    private var productsSection: some View {
        Section(
            String(localized: "paywall.products", defaultValue: "方案", comment: "Products section")
        ) {
            if entitlementManager.isLoading, entitlementManager.products.isEmpty {
                ProgressView()
            } else if entitlementManager.products.isEmpty {
                Text(
                    String(
                        localized: "paywall.products.empty",
                        defaultValue: "暂无可用订阅",
                        comment: "No products"
                    )
                )
                .foregroundStyle(.secondary)
            } else {
                ForEach(entitlementManager.products) { product in
                    Button {
                        Task { await entitlementManager.purchase(product) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.displayName)
                                    .font(.body.weight(.medium))
                                Text(product.displayPrice)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .disabled(entitlementManager.isLoading)
                }
            }
        }
    }

    private var restoreSection: some View {
        Section {
            Button {
                Task { await entitlementManager.restorePurchases() }
            } label: {
                Text(
                    String(localized: "paywall.restore", defaultValue: "恢复购买", comment: "Restore purchases")
                )
            }
            .disabled(entitlementManager.isLoading)
        } footer: {
            Text(
                String(
                    localized: "paywall.restore.footer",
                    defaultValue: "使用同一 Apple ID 购买过？可在此恢复订阅。",
                    comment: "Restore footer"
                )
            )
        }
    }

    private var placementFooter: String {
        let format = String(
            localized: "paywall.placement.footer.format",
            defaultValue: "入口：%@",
            comment: "Placement footer; %@ is placement name"
        )
        return String(format: format, locale: .current, placementDisplayName)
    }

    private var placementDisplayName: String {
        switch placement {
        case .activity:
            String(localized: "paywall.placement.activity", defaultValue: "活动", comment: "Activity placement")
        case .likes:
            String(localized: "paywall.placement.likes", defaultValue: "喜欢", comment: "Likes placement")
        case .community:
            String(localized: "paywall.placement.community", defaultValue: "社区", comment: "Community placement")
        case .messages:
            String(localized: "paywall.placement.messages", defaultValue: "消息", comment: "Messages placement")
        case .settings:
            String(localized: "paywall.placement.settings", defaultValue: "设置", comment: "Settings placement")
        }
    }
}

#Preview("Paywall — products") {
    PaywallView(
        entitlementManager: EntitlementManager(storeKit: MockStoreKitService()),
        placement: .activity,
        onDismiss: {}
    )
}

#Preview("Paywall — subscribed") {
    let manager = EntitlementManager(storeKit: MockStoreKitService())
    PaywallView(
        entitlementManager: manager,
        placement: .messages,
        onDismiss: {}
    )
    .task {
        _ = await manager.refresh()
    }
}
