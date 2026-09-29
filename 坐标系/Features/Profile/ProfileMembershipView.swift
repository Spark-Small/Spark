//
//  ProfileMembershipView.swift
//  坐标系
//
//  会员入口（StoreKit / 演示仅 DEBUG）。
//

import CoordinateModels
import CoordinateFeatureFlags
import StoreKit
import SwiftUI
import TipKit

struct ProfileMembershipView: View {
    @Environment(MembershipStore.self) private var membership
    @Environment(WalletStore.self) private var wallet
    @Environment(WalletPassStore.self) private var passStore
    @Environment(PhotoVerificationStore.self) private var photoVerification
    @Environment(AppModel.self) private var app
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var issuedPassID: UUID?
    @State private var showCreateAccount = false

    private let membershipCents = 2_800
    private let membershipTip = MembershipTip()

    var body: some View {
        Form {
            if app.auth.isGuest {
                Section {
                    Text(GuestAccessGate.commerceReason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("创建账号后开通") {
                        showCreateAccount = true
                    }
                    .fontWeight(.semibold)
                }
            }

            Section {
                TrustCredentialBadgeStrip(
                    photoVerified: photoVerification.isVerified(for: app.user),
                    isMember: membership.isEntitled,
                    revealLocked: true
                )
                LabeledContent("当前状态", value: membership.isEntitled ? "已开通" : "未开通")
            } header: {
                Text("会员状态")
            } footer: {
                if !membership.isEntitled {
                    Text(membershipFooterText)
                }
            }

            Section {
                Label("活动优先提醒", systemImage: "bell.badge")
                    .platformContentSymbolStyle()
                Label("专属身份标识", systemImage: "checkmark.seal.fill")
                    .platformContentSymbolStyle()
                Label("更多内容收藏空间", systemImage: "bookmark.fill")
                    .platformContentSymbolStyle()
                Label("会员卡可加入 Apple Wallet", systemImage: "wallet.bifold")
                    .platformContentSymbolStyle()
            } header: {
                Text("会员权益")
            } footer: {
                Text("开通后可在活动、社区与消息中展示会员标识。")
            }

            if !membership.isEntitled, !app.auth.isGuest, !YouthModePreference.isEnabled {
                Section {
                    SubscriptionStoreView(productIDs: Array(MembershipStore.productIDs)) {
                        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
                            Text("坐标系会员")
                                .font(.title2.weight(.bold))
                            Text("优先提醒、会员标识与更多收藏空间。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
                        .popoverTip(membershipTip)
                    }
                    .storeButton(.visible, for: .restorePurchases)
                    .onInAppPurchaseCompletion { _, result in
                        await handleStoreKitPurchase(result)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("App Store 订阅")
                }

                #if DEBUG
                Section {
                    Button("本地演示开通（钱包扣款）") {
                        activateMembershipDemo()
                    }
                    .disabled(isProcessing)
                } footer: {
                    Text(
                        "DEBUG：无 StoreKit 环境时可用钱包余额演示开通（\(WalletMoney.formatted(cents: membershipCents))）。"
                    )
                }
                #endif
            }

            if membership.isEntitled {
                Section {
                    WalletPassFace(
                        content: WalletPassFaceFactory.membership(holderName: app.user.name),
                        symbol: "person.text.rectangle"
                    )
                    .listRowInsets(PlatformWalletPassListRow.insets)
                    .listRowBackground(Color.clear)
                } header: {
                    Text("会员票面")
                }
            }

            if membership.isEntitled, let issuedPassID {
                Section("Apple Wallet") {
                    NavigationLink("查看会员通行证") {
                        WalletPassDetailView(passID: issuedPassID)
                    }
                }
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("会员中心")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateAccount) {
            ProfileCreateAccountSheet(
                session: app.auth,
                reason: GuestAccessGate.commerceReason
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert("无法开通", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await membership.refreshEntitlement()
            if membership.isEntitled {
                applyActiveMembership()
            }
        }
        .onAppear {
            if membership.isEntitled {
                issuedPassID = passStore.issueMembershipCard(holderName: app.user.name).id
            }
        }
        .onChange(of: membership.isEntitled) { _, entitled in
            guard entitled else { return }
            applyActiveMembership()
        }
    }

    private var membershipFooterText: String {
        if YouthModePreference.isEnabled {
            return GuestAccessGate.youthCommerceReason
        }
        if app.auth.isGuest {
            return "创建账号后即可开通会员。"
        }
        return "通过 App Store 订阅开通会员，可随时在系统「订阅」中管理。"
    }

    @MainActor
    private func handleStoreKitPurchase(
        _ result: Result<Product.PurchaseResult, any Error>
    ) async {
        switch result {
        case .success(.success):
            await membership.refreshEntitlement()
            if membership.isEntitled {
                applyActiveMembership()
            }
        case .success(.userCancelled), .success(.pending):
            break
        case .success:
            break
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func applyActiveMembership() {
        issuedPassID = passStore.issueMembershipCard(holderName: app.user.name).id
    }

    private func activateMembershipDemo() {
        #if DEBUG
        guard !YouthModePreference.isEnabled else { return }
        guard GuestAccessGate.allow(app.auth, presentCreateAccount: $showCreateAccount) else { return }
        guard !membership.isEntitled, !isProcessing else { return }
        isProcessing = true
        let outcome = wallet.charge(
            amountCents: membershipCents,
            method: .wallet,
            kind: .membership,
            title: "开通会员",
            subtitle: "坐标系会员"
        )
        isProcessing = false
        switch outcome {
        case .success:
            membership.applyDemoEntitlement()
            applyActiveMembership()
        case .insufficientBalance:
            errorMessage = "余额不足，请先前往钱包充值。"
        case .failed(let message):
            errorMessage = message
        }
        #endif
    }
}

