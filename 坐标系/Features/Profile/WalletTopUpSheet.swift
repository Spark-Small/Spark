//
//  WalletTopUpSheet.swift
//  坐标系
//
//  钱包充值 Sheet（Release 诚实不可用）。
//

import CoordinateModels
import SwiftUI

struct WalletTopUpSheet: View {
    @Environment(WalletStore.self) private var wallet
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCents = 10_000
    @State private var selectedMethod: PaymentMethod = .applePay
    @State private var isProcessing = false

    private let presets = [5_000, 10_000, 20_000, 50_000]
    private var youthBlocked: Bool { YouthModePreference.isEnabled }
    /// Release 不得伪造 Apple Pay / 微信 / 支付宝到账（审核 3.1.1 / 2.3.1）。
    private var allowsDemoTopUp: Bool { CommercePaymentPolicy.allowsSimulatedExternalCheckout }

    private var topUpFooterText: String {
        if youthBlocked {
            return GuestAccessGate.youthCommerceReason
        }
        if allowsDemoTopUp {
            return "DEBUG：本地演示充值，立即记入钱包余额。"
        }
        return "正式充值通道接入中。数字商品请通过 App Store；线下服务将走合规支付。"
    }

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
                    .disabled(youthBlocked || !allowsDemoTopUp)
                } header: {
                    Text("到账方式")
                } footer: {
                    Text(topUpFooterText)
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
                    Button(allowsDemoTopUp ? "确认充值" : "暂不可用") { confirmTopUp() }
                        .fontWeight(.semibold)
                        .disabled(isProcessing || youthBlocked || !allowsDemoTopUp)
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
        guard allowsDemoTopUp, !youthBlocked, !isProcessing else { return }
        isProcessing = true
        Task { @MainActor in
            #if DEBUG
            try? await Task.sleep(for: .milliseconds(400))
            #endif
            _ = wallet.topUp(amountCents: selectedCents, method: selectedMethod)
            isProcessing = false
            dismiss()
        }
    }
}

