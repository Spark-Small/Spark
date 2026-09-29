//
//  ActivityJoinConfirmSheet.swift
//  坐标系
//
//  参加前确认、支付前确认。
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

enum ActivityJoinPromotionMode: Equatable {
    case standard
    case waitlist
}

struct ActivityJoinConfirmSheet: View {
    let activity: Activity
    var conflicts: [Activity] = []
    var promotionMode: ActivityJoinPromotionMode = .standard
    var onConfirm: (_ note: String?) -> Void

    @Environment(WalletStore.self) private var wallet
    @Environment(WalletPassStore.self) private var passStore
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var selectedMethod: PaymentMethod = .wallet
    @State private var pendingOrder: ActivityOrder?
    @State private var isProcessing = false
    @State private var paymentTask: Task<Void, Never>?
    @State private var didCommitJoin = false
    @State private var errorMessage: String?

    private var payable: (display: String, cents: Int)? {
        ActivityFeeParser.payableAmount(for: activity)
    }

    private var needsPayment: Bool {
        activity.requiresInAppPayment && !ActivityPaymentStore.hasPaid(for: activity.id)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    joinConfirmField("活动", systemImage: activity.category.coverSymbol(forSeed: activity.coverSeed)) {
                        Text(activity.title)
                            .multilineTextAlignment(.trailing)
                    }
                    joinConfirmField("时间", systemImage: "calendar") {
                        Text(Formatters.activityEventTime(from: activity.date))
                    }
                    joinConfirmField("地点", systemImage: "mappin.and.ellipse") {
                        Text(activity.location)
                            .multilineTextAlignment(.trailing)
                    }
                    joinConfirmField("费用", systemImage: "tag.fill") {
                        Text(activity.fee)
                    }
                    joinConfirmField("名额", systemImage: "person.2.fill") {
                        Text("\(activity.joined)/\(activity.capacity)")
                    }
                    if needsPayment, let payable {
                        joinConfirmField("应付金额", systemImage: "yensign.circle.fill") {
                            Text(WalletMoney.formatted(cents: payable.cents))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                } footer: {
                    Text(confirmFooterMessage)
                }

                if !conflicts.isEmpty {
                    Section {
                        ForEach(conflicts) { conflict in
                            Label {
                                VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
                                    Text(conflict.title)
                                        .font(.body.weight(.semibold))
                                    Text("\(Formatters.activityEventTime(from: conflict.date)) · \(conflict.location)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            } icon: {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .symbolRenderingMode(.multicolor)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    } header: {
                        Label {
                            Text(ActivityDetailCopy.joinConflictTitle(conflicts.count))
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .symbolRenderingMode(.multicolor)
                        }
                    } footer: {
                        Text(ActivityDetailCopy.joinConflictFooter)
                    }
                }

                if needsPayment {
                    Section {
                        Picker("支付方式", selection: $selectedMethod) {
                            ForEach(CommercePaymentPolicy.checkoutMethods) { method in
                                Label {
                                    Text(method == .wallet
                                         ? "\(method.displayName)（\(wallet.balanceText)）"
                                         : method.displayName)
                                } icon: {
                                    Image(systemName: method.systemImage)
                                        .symbolRenderingMode(.multicolor)
                                }
                                .tag(method)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        .disabled(isProcessing)
                    } header: {
                        Label {
                            Text("支付方式")
                        } icon: {
                            Image(systemName: "creditcard.fill")
                                .symbolRenderingMode(.multicolor)
                        }
                    } footer: {
                        Text(CommercePaymentPolicy.checkoutFooterSupplement)
                    }
                }

                Section {
                    TextField(ActivityDetailCopy.joinConfirmNotePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .disabled(isProcessing)
                } header: {
                    Label {
                        Text("留言")
                    } icon: {
                        Image(systemName: "text.bubble")
                            .symbolRenderingMode(.multicolor)
                    }
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
                    Button(confirmActionTitle) {
                        confirm()
                    }
                    .fontWeight(.semibold)
                    .disabled(isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView(ActivityDetailCopy.paymentProcessing)
                        .platformProcessingOverlayChrome()
                }
            }
            .alert("无法完成", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear(perform: preparePendingOrderIfNeeded)
            .onDisappear {
                paymentTask?.cancel()
                paymentTask = nil
                if !didCommitJoin, let pendingOrder {
                    ActivityPaymentStore.cancelPending(orderID: pendingOrder.id)
                }
            }
        }
        .platformSheet(needsPayment ? .browser : .confirm, interactiveDismissDisabled: isProcessing)
    }

    @ViewBuilder
    private func joinConfirmField<Value: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Value
    ) -> some View {
        LabeledContent {
            content()
        } label: {
            Label(title, systemImage: systemImage)
                .symbolRenderingMode(.multicolor)
        }
    }

    private var navigationTitle: String {
        promotionMode == .waitlist
            ? ActivityDetailCopy.waitlistConfirmTitle
            : ActivityDetailCopy.joinConfirmTitle
    }

    private var confirmFooterMessage: String {
        switch promotionMode {
        case .waitlist:
            return needsPayment
                ? ActivityDetailCopy.waitlistConfirmPaidHint
                : ActivityDetailCopy.waitlistConfirmMessage
        case .standard:
            return needsPayment
                ? ActivityDetailCopy.joinConfirmPaidHint
                : ActivityDetailCopy.joinConfirmMessage
        }
    }

    private var confirmActionTitle: String {
        if promotionMode == .waitlist {
            if needsPayment {
                return ActivityDetailCopy.waitlistPromotePayAction
            }
            return ActivityDetailCopy.waitlistPromotePaidAction
        }
        return needsPayment ? ActivityDetailCopy.joinConfirmPayAction : ActivityDetailCopy.joinConfirmTitle
    }

    private var trimmedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func preparePendingOrderIfNeeded() {
        guard needsPayment, pendingOrder == nil else { return }
        pendingOrder = ActivityPaymentStore.createPendingOrder(for: activity)
    }

    private func cancelFlow() {
        paymentTask?.cancel()
        paymentTask = nil
        isProcessing = false
        if let pendingOrder {
            ActivityPaymentStore.cancelPending(orderID: pendingOrder.id)
        }
        dismiss()
    }

    private func confirm() {
        guard app.requireIdentityAccess() else { return }
        if needsPayment {
            processPaymentThenJoin()
        } else {
            onConfirm(trimmedNote)
            didCommitJoin = true
            dismiss()
        }
    }

    private func processPaymentThenJoin() {
        guard !isProcessing else { return }
        if app.auth.isGuest {
            errorMessage = GuestAccessGate.commerceReason
            return
        }
        guard app.requireIdentityAccess() else { return }
        if selectedMethod != .wallet, !CommercePaymentPolicy.allowsSimulatedExternalCheckout {
            errorMessage = CommercePaymentPolicy.externalCheckoutUnavailableMessage
            return
        }
        let amountCents = payable?.cents ?? pendingOrder?.amountCents ?? 0
        if selectedMethod == .wallet, !wallet.canAfford(amountCents) {
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
            let ensured = pendingOrder ?? ActivityPaymentStore.createPendingOrder(for: activity)
            guard let ensured else {
                isProcessing = false
                paymentTask = nil
                errorMessage = "无法创建订单"
                return
            }
            pendingOrder = ensured
            let outcome = ActivityPaymentStore.markPaid(orderID: ensured.id, method: selectedMethod)
            isProcessing = false
            paymentTask = nil
            switch outcome {
            case .success:
                didCommitJoin = true
                if let paid = ActivityPaymentStore.order(id: ensured.id) {
                    passStore.issueActivityTicket(order: paid, activity: activity)
                }
                onConfirm(trimmedNote)
                dismiss()
            case .insufficientBalance:
                errorMessage = "余额不足，请充值或改用其他支付方式。"
            case .failed(let message):
                errorMessage = message
            }
        }
    }
}
