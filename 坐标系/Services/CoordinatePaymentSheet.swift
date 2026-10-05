//
//  CoordinatePaymentSheet.swift
//  坐标系
//
//  共用结账 Form：方法列表仅来自 CommercePaymentPolicy。
//

import CoordinateFeatureFlags
import SwiftUI

struct CoordinatePaymentSheet: View {
    let navigationTitle: String
    let summary: [(label: String, value: String)]
    let amountCents: Int
    var footer: String = "支付成功后将更新订单状态。"
    var preferredMethod: PaymentMethod = .wallet
    var onConfirm: (PaymentMethod) async -> PaymentOutcome
    var onCancel: () -> Void = {}

    @Environment(WalletStore.self) private var wallet
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: PaymentMethod
    @State private var isProcessing = false
    @State private var paymentTask: Task<Void, Never>?
    @State private var errorMessage: String?

    init(
        navigationTitle: String,
        summary: [(label: String, value: String)],
        amountCents: Int,
        footer: String = "支付成功后将更新订单状态。",
        preferredMethod: PaymentMethod = .wallet,
        onConfirm: @escaping (PaymentMethod) async -> PaymentOutcome,
        onCancel: @escaping () -> Void = {}
    ) {
        self.navigationTitle = navigationTitle
        self.summary = summary
        self.amountCents = amountCents
        self.footer = footer
        let allowed = CommercePaymentPolicy.checkoutMethods
        let initial = allowed.contains(preferredMethod) ? preferredMethod : (allowed.first ?? .wallet)
        self.preferredMethod = initial
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _selectedMethod = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Array(summary.enumerated()), id: \.offset) { _, row in
                        LabeledContent(row.label) {
                            Text(row.value)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    LabeledContent("应付金额") {
                        Text(WalletMoney.formatted(cents: amountCents))
                            .fontWeight(.bold)
                    }
                } footer: {
                    Text(footer)
                }

                Section {
                    Picker("支付方式", selection: $selectedMethod) {
                        ForEach(CommercePaymentPolicy.checkoutMethods) { method in
                            Text(method == .wallet
                                 ? "\(method.displayName)（\(wallet.balanceText)）"
                                 : method.displayName)
                            .tag(method)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .disabled(isProcessing)
                } header: {
                    Text("支付方式")
                } footer: {
                    Text(CommercePaymentPolicy.checkoutFooterSupplement)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { cancelFlow() }
                        .disabled(isProcessing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("支付") { processPayment() }
                        .fontWeight(.semibold)
                        .disabled(isProcessing || amountCents <= 0)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("正在支付…")
                        .platformProcessingOverlayChrome()
                }
            }
            .alert("无法支付", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onDisappear {
                paymentTask?.cancel()
                paymentTask = nil
            }
        }
        .platformSheet(.browser, interactiveDismissDisabled: isProcessing)
    }

    private func cancelFlow() {
        paymentTask?.cancel()
        paymentTask = nil
        isProcessing = false
        onCancel()
        dismiss()
    }

    private func processPayment() {
        guard !isProcessing else { return }
        if selectedMethod != .wallet, !CommercePaymentPolicy.allowsSimulatedExternalCheckout {
            CommerceAnalytics.checkoutBlocked(method: selectedMethod.rawValue)
            errorMessage = CommercePaymentPolicy.externalCheckoutUnavailableMessage
            return
        }
        if selectedMethod == .wallet,
           !FeatureFlags.useRemoteWallet,
           !wallet.canAfford(amountCents) {
            errorMessage = "余额不足，请充值或改用其他支付方式。"
            return
        }
        isProcessing = true
        paymentTask?.cancel()
        paymentTask = Task { @MainActor in
            #if DEBUG
            try? await Task.sleep(for: .milliseconds(400))
            #endif
            guard !Task.isCancelled else { return }
            let outcome = await onConfirm(selectedMethod)
            isProcessing = false
            paymentTask = nil
            switch outcome {
            case .success:
                dismiss()
            case .insufficientBalance:
                errorMessage = "余额不足，请充值或改用其他支付方式。"
            case .failed(let message):
                errorMessage = message
            }
        }
    }
}
