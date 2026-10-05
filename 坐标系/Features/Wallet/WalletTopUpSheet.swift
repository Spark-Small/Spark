//
//  WalletTopUpSheet.swift
//  坐标系
//
//  钱包充值：DEBUG 本机演示；`useRemoteWallet` 走服务端意图；否则诚实不可用。
//

import CoordinateModels
import SwiftUI

struct WalletTopUpSheet: View {
    @Environment(WalletStore.self) private var wallet
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCents = 10_000
    @State private var selectedMethod: PaymentMethod = .wechat
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let presets = [5_000, 10_000, 20_000, 50_000]
    private var youthBlocked: Bool { YouthModePreference.isEnabled }
    private var topUpMethods: [PaymentMethod] { CommercePaymentPolicy.topUpMethods }
    private var canAttempt: Bool { CommercePaymentPolicy.canAttemptTopUp }

    private var confirmTitle: String {
        if canAttempt { return "确认充值" }
        return "暂不可用"
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
                    .disabled(youthBlocked || !canAttempt)
                }

                if !topUpMethods.isEmpty {
                    Section {
                        Picker("方式", selection: $selectedMethod) {
                            ForEach(topUpMethods) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        .disabled(youthBlocked || !canAttempt)
                    } header: {
                        Text("到账方式")
                    } footer: {
                        Text(CommercePaymentPolicy.topUpFooterDisclosure)
                    }
                } else {
                    Section {
                        Text(CommercePaymentPolicy.topUpFooterDisclosure)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("到账方式")
                    }
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
                    Button(confirmTitle) { confirmTopUp() }
                        .fontWeight(.semibold)
                        .disabled(isProcessing || youthBlocked || !canAttempt)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("正在充值…")
                        .platformProcessingOverlayChrome()
                }
            }
            .alert(
                ProfileWalletCopy.alertTitle,
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(ProfileWalletCopy.alertOK, role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if youthBlocked {
                    dismiss()
                    return
                }
                if let first = topUpMethods.first, !topUpMethods.contains(selectedMethod) {
                    selectedMethod = first
                }
            }
        }
        .platformSheet(.confirm, interactiveDismissDisabled: isProcessing)
    }

    private func confirmTopUp() {
        guard canAttempt, !youthBlocked, !isProcessing else { return }
        isProcessing = true
        Task { @MainActor in
            let outcome = await wallet.topUpAsync(
                amountCents: selectedCents,
                method: selectedMethod
            )
            isProcessing = false
            switch outcome {
            case .success:
                dismiss()
            case .insufficientBalance:
                errorMessage = "余额状态异常，请稍后重试。"
            case .failed(let message):
                errorMessage = message
            }
        }
    }
}
