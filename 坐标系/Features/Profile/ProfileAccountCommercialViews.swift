//
//  ProfileAccountCommercialViews.swift
//  坐标系
//
//  「我的」账号创建、会员与钱包入口页。
//

import SwiftUI

struct ProfileCreateAccountSheet: View {
    @Bindable var session: LocalAuthSession
    @Environment(\.dismiss) private var dismiss
    /// 弹层说明：交易门槛 / 资料门槛等
    var reason: String = GuestAccessGate.commerceReason

    @State private var phone = ""
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var hasAgreedToLegal = false
    @State private var showLegalAlert = false
    @State private var pendingCreateAction: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section("手机号") {
                    LabeledContent("手机号") {
                        TextField("手机号码", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("验证码") {
                        SecureField("输入验证码", text: $code)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(PlatformStatus.danger)
                    }
                }

                Section {
                    LegalConsentCheckbox(
                        isChecked: $hasAgreedToLegal,
                        showAlert: $showLegalAlert,
                        centersContent: false
                    )
                } footer: {
                    Text("创建账号前需同意用户协议与隐私政策。")
                }

                Section {
                    Button {
                        requireLegalConsent {
                            session.signInDemoApple()
                            dismiss()
                        }
                    } label: {
                        Label("使用 Apple 创建", systemImage: "apple.logo")
                    }
                    Button {
                        requireLegalConsent {
                            session.signInDemoWeChat()
                            dismiss()
                        }
                    } label: {
                        Label("使用微信创建", systemImage: "message")
                    }
                } header: {
                    Text("其他方式")
                } footer: {
                    Text("演示环境下一键绑定身份；正式版将接入系统 Sign in with Apple 与微信开放平台。本地演示验证码：\(LocalAuthSession.demoCode)。")
                }
            }
            .navigationTitle("创建账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建账号") {
                        requireLegalConsent(createAccount)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .legalConsentAlert(
            isPresented: $showLegalAlert,
            onAgree: {
                hasAgreedToLegal = true
                let action = pendingCreateAction
                pendingCreateAction = nil
                action?()
                Task { await PermissionLaunchPrompts.requestTrackingAfterConsentIfNeeded() }
            },
            onReject: {
                pendingCreateAction = nil
            }
        )
        .platformSheet(.form)
    }

    private func requireLegalConsent(_ action: @escaping () -> Void) {
        if hasAgreedToLegal {
            action()
        } else {
            pendingCreateAction = action
            showLegalAlert = true
        }
    }

    private func createAccount() {
        if session.signIn(phone: phone, code: code) {
            dismiss()
        } else {
            errorMessage = "请输入有效手机号，并使用演示验证码。"
        }
    }
}

struct ProfileMembershipView: View {
    @AppStorage("profile.membership.active") private var isActive = false
    @Environment(WalletStore.self) private var wallet
    @Environment(AppModel.self) private var app
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var issuedPassID: UUID?
    @State private var showCreateAccount = false

    private let membershipCents = 2_800

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
                    photoVerified: {
                        _ = PhotoVerificationStore.shared.isVerified
                        return PhotoVerificationStore.shared.isVerified(for: app.user.name)
                    }(),
                    isMember: isActive,
                    revealLocked: true
                )
                LabeledContent("当前状态", value: isActive ? "已开通" : "未开通")
                if !isActive {
                    LabeledContent("开通费用", value: WalletMoney.formatted(cents: membershipCents))
                }
            } header: {
                Text("会员状态")
            } footer: {
                if !isActive {
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

            if isActive {
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

            if isActive, let issuedPassID {
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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isActive ? "已开通" : "开通") {
                    activateMembership()
                }
                .fontWeight(.semibold)
                .disabled(
                    isActive
                        || isProcessing
                        || app.auth.isGuest
                        || YouthModePreference.isEnabled
                )
            }
        }
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
        .onAppear {
            if isActive {
                issuedPassID = WalletPassStore.shared.issueMembershipCard(holderName: app.user.name).id
            }
        }
    }

    private var membershipFooterText: String {
        if YouthModePreference.isEnabled {
            return GuestAccessGate.youthCommerceReason
        }
        if app.auth.isGuest {
            return "创建账号后即可开通会员。"
        }
        return "本地演示：从钱包余额扣款；开通后签发会员通行证。"
    }

    private func activateMembership() {
        guard !YouthModePreference.isEnabled else { return }
        guard GuestAccessGate.allow(app.auth, presentCreateAccount: $showCreateAccount) else { return }
        guard !isActive, !isProcessing else { return }
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
            isActive = true
            issuedPassID = WalletPassStore.shared.issueMembershipCard(holderName: app.user.name).id
        case .insufficientBalance:
            errorMessage = "余额不足，请先前往钱包充值。"
        case .failed(let message):
            errorMessage = message
        }
    }
}

struct ProfileWalletView: View {
    @Environment(WalletStore.self) private var wallet
    @Environment(AppModel.self) private var app
    @AppStorage("profile.membership.active") private var membershipActive = false
    @AppStorage("profile.wallet.couponCount") private var couponCount = 6
    @AppStorage("profile.wallet.points") private var points = 20
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
                    isMember: membershipActive,
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
                LabeledContent(ProfileDashboardCopy.walletCoupons, value: "\(couponCount)")
                LabeledContent(ProfileDashboardCopy.walletPoints, value: "\(points)")
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
                    Text(membershipActive ? "已开通" : "未开通")
                        .foregroundStyle(membershipActive ? PlatformStatus.success : .secondary)
                } label: {
                    Label("会员", systemImage: "checkmark.seal")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    ProfileOrdersView()
                } label: {
                    Label("我的订单", systemImage: "list.bullet.rectangle")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text("支付设置")
            } footer: {
                Text("活动票与陪玩预约凭证在「我的」活动区查看；点银行卡面可充值。")
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
private struct WalletLedgerRow: View {
    let entry: WalletLedgerEntry

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            Image(systemName: entry.kind.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: PlatformMetrics.navigationBarButtonSide * 0.7, alignment: .center)
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

struct WalletTopUpSheet: View {
    @Environment(WalletStore.self) private var wallet
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCents = 10_000
    @State private var selectedMethod: PaymentMethod = .applePay
    @State private var isProcessing = false

    private let presets = [5_000, 10_000, 20_000, 50_000]
    private var youthBlocked: Bool { YouthModePreference.isEnabled }

    var body: some View {
        NavigationStack {
            Form {
                Section("充值金额") {
                    Picker("金额", selection: $selectedCents) {
                        ForEach(presets, id: \.self) { cents in
                            Text(WalletMoney.formatted(cents: cents)).tag(cents)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .disabled(youthBlocked)
                }

                Section {
                    Picker("方式", selection: $selectedMethod) {
                        Text(PaymentMethod.applePay.displayName).tag(PaymentMethod.applePay)
                        Text(PaymentMethod.wechat.displayName).tag(PaymentMethod.wechat)
                        Text(PaymentMethod.alipay.displayName).tag(PaymentMethod.alipay)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .disabled(youthBlocked)
                } header: {
                    Text("到账方式")
                } footer: {
                    Text(
                        youthBlocked
                            ? GuestAccessGate.youthCommerceReason
                            : "本地演示充值，立即记入钱包余额。"
                    )
                }
            }
            .navigationTitle("充值")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isProcessing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认充值") { confirmTopUp() }
                        .fontWeight(.semibold)
                        .disabled(isProcessing || youthBlocked)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("正在充值…")
                        .platformProcessingOverlayChrome()
                }
            }
            .onAppear {
                if youthBlocked {
                    dismiss()
                }
            }
        }
        .platformSheet(.confirm, interactiveDismissDisabled: isProcessing)
    }

    private func confirmTopUp() {
        guard !youthBlocked, !isProcessing else { return }
        isProcessing = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            _ = wallet.topUp(amountCents: selectedCents, method: selectedMethod)
            isProcessing = false
            dismiss()
        }
    }
}

// MARK: - Become companion

/// 「成为陪玩」入驻占位：前期只保留入口与说明，正式版再接审核流。
struct ProfileBecomeCompanionView: View {
    var body: some View {
        ContentUnavailableView(
            ProfileDashboardCopy.becomeCompanion,
            systemImage: "person.badge.plus",
            description: Text("完善资料并通过审核后，即可在陪玩页接单。入驻流程将在正式版开放。")
        )
        .navigationTitle(ProfileDashboardCopy.becomeCompanion)
        .navigationBarTitleDisplayMode(.inline)
    }
}
