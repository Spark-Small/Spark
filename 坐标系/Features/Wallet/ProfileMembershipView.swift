//
//  ProfileMembershipView.swift
//  坐标系
//
//  会员中心（无后端）：StoreKit Configuration 订阅 + 本机权益投影；DEBUG 演示不被刷新冲掉。
//

import StoreKit
import SwiftUI

struct ProfileMembershipView: View {
    @Environment(MembershipStore.self) private var membership
    @Environment(WalletStore.self) private var wallet
    @Environment(PhotoVerificationStore.self) private var photoVerification
    @Environment(AppModel.self) private var app

    @State private var showManageSubscriptions = false
    @State private var isProcessingDemo = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private let demoMembershipCents = 2_800

    var body: some View {
        Group {
            if YouthModePreference.isEnabled {
                youthBlocked
            } else if membership.isEntitled {
                manageForm
            } else if membership.productsLoadFailed {
                unavailableForm
            } else {
                subscribeStore
            }
        }
        .navigationTitle(ProfileMembershipCopy.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingToolbar }
        .alert(
            ProfileMembershipCopy.alertTitle,
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(ProfileMembershipCopy.alertOK, role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .manageSubscriptionsSheet(
            isPresented: $showManageSubscriptions,
            subscriptionGroupID: MembershipStore.subscriptionGroupID
        )
        .task {
            await reloadMembership(syncStore: false)
        }
        .refreshable {
            await reloadMembership(syncStore: true)
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if membership.isRefreshing || isRestoring {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(ProfileMembershipCopy.refreshStatus) {
                    Task { await reloadMembership(syncStore: false) }
                }
                .platformNavigationBarItemChrome()
            }
        }
    }

    // MARK: - Youth

    private var youthBlocked: some View {
        ProfileLibraryEmptyView(
            title: ProfileMembershipCopy.youthTitle,
            systemImage: ProfileMembershipCopy.youthSystemImage,
            description: CommerceAccessCopy.youthCommerceReason
        )
    }

    // MARK: - Subscribe

    private var subscribeStore: some View {
        SubscriptionStoreView(groupID: MembershipStore.subscriptionGroupID) {
            ProfileMembershipMarketingContent()
        }
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStoreButtonLabel(.multiline)
        .onInAppPurchaseCompletion { _, result in
            await handleStoreKitPurchase(result)
        }
        #if DEBUG
        .safeAreaInset(edge: .bottom, spacing: 0) {
            demoActivateBar
        }
        #endif
    }

    // MARK: - Products unavailable (still no backend)

    private var unavailableForm: some View {
        Form {
            Section {
                ContentUnavailableView {
                    Label(
                        ProfileMembershipCopy.unavailableTitle,
                        systemImage: "storefront"
                    )
                } description: {
                    Text(ProfileMembershipCopy.unavailableDescription)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                Button(ProfileMembershipCopy.retryLoad) {
                    Task { await reloadMembership(syncStore: false) }
                }
                Button(ProfileMembershipCopy.restorePurchases) {
                    Task { await restore() }
                }
                .disabled(isRestoring)
            }

            #if DEBUG
            demoDebugSection
            #endif
        }
        .profileSecondaryListChrome(flushTop: true)
    }

    // MARK: - Manage

    private var manageForm: some View {
        Form {
            Section {
                Label {
                    TrustCredentialBadgeStrip(
                        photoVerified: photoVerification.isVerified(for: app.user),
                        isMember: true,
                        revealLocked: true
                    )
                } icon: {
                    Image(systemName: "person.badge.shield.checkmark")
                }
                .platformContentSymbolStyle()
                LabeledContent {
                    Text(ProfileMembershipCopy.statusActive)
                        .foregroundStyle(PlatformStatus.success)
                } label: {
                    Label(ProfileMembershipCopy.statusLabel, systemImage: "checkmark.seal.fill")
                        .platformContentSymbolStyle()
                }
                LabeledContent {
                    Text(
                        ProfileMembershipCopy.planDisplayName(
                            productDisplayName: membership.monthlyProduct?.displayName
                        )
                    )
                } label: {
                    Label(ProfileMembershipCopy.planLabel, systemImage: "calendar")
                        .platformContentSymbolStyle()
                }
                LabeledContent {
                    Text(ProfileMembershipCopy.expirationText(date: membership.expirationDate))
                } label: {
                    Label(ProfileMembershipCopy.renewLabel, systemImage: "clock")
                        .platformContentSymbolStyle()
                }
                LabeledContent {
                    Text(sourceLabel)
                } label: {
                    Label(ProfileMembershipCopy.sourceLabel, systemImage: "info.circle")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text(ProfileMembershipCopy.statusSection)
            } footer: {
                Text(sourceFooter)
            }

            Section {
                ForEach(ProfileMembershipCopy.marketingBenefits, id: \.title) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .platformContentSymbolStyle()
                }
            } header: {
                Text(ProfileMembershipCopy.benefitsSection)
            } footer: {
                Text(ProfileMembershipCopy.benefitsFooter)
            }

            Section {
                if membership.source == .storeKit {
                    Button {
                        showManageSubscriptions = true
                    } label: {
                        Label(
                            ProfileMembershipCopy.manageSubscriptions,
                            systemImage: "creditcard"
                        )
                        .platformContentSymbolStyle()
                    }
                }
                Button {
                    Task { await restore() }
                } label: {
                    Label(
                        ProfileMembershipCopy.restorePurchases,
                        systemImage: "arrow.clockwise"
                    )
                    .platformContentSymbolStyle()
                }
                .disabled(isRestoring)
            } header: {
                Text(ProfileMembershipCopy.manageSection)
            } footer: {
                Text(ProfileMembershipCopy.manageFooter)
            }

            #if DEBUG
            if membership.source == .demoLocal {
                demoDebugSection
            }
            #endif
        }
        .profileSecondaryListChrome(flushTop: true)
    }

    private var sourceLabel: String {
        switch membership.source {
        case .storeKit: ProfileMembershipCopy.sourceStoreKit
        case .demoLocal: ProfileMembershipCopy.sourceDemo
        case .none: ProfileMembershipCopy.statusInactive
        }
    }

    private var sourceFooter: String {
        switch membership.source {
        case .demoLocal: ProfileMembershipCopy.sourceFooterDemo
        default: ProfileMembershipCopy.sourceFooterStoreKit
        }
    }

    // MARK: - DEBUG

    #if DEBUG
    private var demoActivateBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(ProfileMembershipCopy.demoActivate) {
                activateMembershipDemo()
            }
            .disabled(isProcessingDemo)
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
            Text(
                "\(ProfileMembershipCopy.demoFooterPrefix)（\(WalletMoney.formatted(cents: demoMembershipCents))）。"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.bottom, PlatformMetrics.sectionHeaderSpacing)
        }
        .background(.bar)
    }

    private var demoDebugSection: some View {
        Section {
            if membership.isEntitled, membership.source == .demoLocal {
                Button(ProfileMembershipCopy.demoClear, role: .destructive) {
                    membership.clearDemoEntitlement()
                }
            } else if !membership.isEntitled {
                Button(ProfileMembershipCopy.demoActivate) {
                    activateMembershipDemo()
                }
                .disabled(isProcessingDemo)
            }
        } header: {
            Text(ProfileMembershipCopy.demoSection)
        } footer: {
            Text(
                "\(ProfileMembershipCopy.demoFooterPrefix)（\(WalletMoney.formatted(cents: demoMembershipCents))）。"
            )
        }
    }
    #endif

    // MARK: - Actions

    private func reloadMembership(syncStore: Bool) async {
        if syncStore {
            try? await AppStore.sync()
        }
        await membership.loadProducts()
        await membership.refreshEntitlement()
    }

    private func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await membership.restorePurchases()
        } catch {
            errorMessage = ProfileMembershipCopy.restoreFailedPrefix + error.localizedDescription
        }
    }

    @MainActor
    private func handleStoreKitPurchase(
        _ result: Result<Product.PurchaseResult, any Error>
    ) async {
        switch result {
        case .success(let purchaseResult):
            switch purchaseResult {
            case .success:
                await membership.refreshEntitlement()
                await membership.loadProducts()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func activateMembershipDemo() {
        #if DEBUG
        guard !YouthModePreference.isEnabled else { return }
        guard !membership.isEntitled, !isProcessingDemo else { return }
        isProcessingDemo = true
        let outcome = wallet.charge(
            amountCents: demoMembershipCents,
            method: .wallet,
            kind: .membership,
            title: ProfileMembershipCopy.brandTitle,
            subtitle: ProfileMembershipCopy.navigationTitle
        )
        isProcessingDemo = false
        switch outcome {
        case .success:
            membership.applyDemoEntitlement()
        case .insufficientBalance:
            errorMessage = ProfileMembershipCopy.insufficientBalance
        case .failed(let message):
            errorMessage = message
        }
        #endif
    }
}
