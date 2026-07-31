//
//  WalletPayment.swift
//  坐标系
//
//  统一本地支付账本（活动 / 陪玩 / 转账 / 充值），对齐 Apple Pay 结账 + Wallet 流水形态。
//

import Foundation
import Observation
import SwiftUI

// MARK: - Money

enum WalletMoney {
    static func formatted(cents: Int) -> String {
        let yuan = Double(cents) / 100
        if yuan.truncatingRemainder(dividingBy: 1) == 0 {
            return "¥\(Int(yuan))"
        }
        return String(format: "¥%.2f", yuan)
    }

    static func signedFormatted(cents: Int) -> String {
        let absText = formatted(cents: abs(cents))
        if cents > 0 { return "+\(absText)" }
        if cents < 0 { return "-\(absText)" }
        return absText
    }

    /// 从「¥120」「120 元」等文案解析分；失败返回 nil
    static func cents(fromDisplay text: String) -> Int? {
        let pattern = /(\d+(?:\.\d{1,2})?)/
        guard let match = text.firstMatch(of: pattern),
              let yuan = Double(match.1)
        else { return nil }
        return max(Int((yuan * 100).rounded()), 1)
    }

    static func cents(fromYuan yuan: Double) -> Int {
        max(Int((yuan * 100).rounded()), 0)
    }
}

// MARK: - Method / Kind

enum PaymentMethod: String, Codable, CaseIterable, Hashable, Identifiable {
    case wallet
    case applePay
    case wechat
    case alipay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wallet: "余额支付"
        case .applePay: "Apple Pay"
        case .wechat: "微信支付"
        case .alipay: "支付宝"
        }
    }

    var systemImage: String {
        switch self {
        case .wallet: "wallet.bifold.fill"
        case .applePay: "applelogo"
        case .wechat: "message.fill"
        case .alipay: "yensign.circle.fill"
        }
    }

    /// 是否扣 / 退应用内余额
    var affectsWalletBalance: Bool { self == .wallet }

    static func resolve(_ raw: String) -> PaymentMethod {
        if let exact = PaymentMethod(rawValue: raw) { return exact }
        switch raw {
        case "余额支付", "wallet", "simulated": return .wallet
        case "Apple Pay", "applePay": return .applePay
        case "微信支付", "wechat": return .wechat
        case "支付宝", "alipay": return .alipay
        default: return .applePay
        }
    }
}

enum WalletEntryKind: String, Codable, Hashable {
    case topUp
    case welcome
    case activityPayment
    case activityRefund
    case bookingPayment
    case bookingRefund
    case transferOut
    case transferIn
    case transferRefund
    case membership

    var titleFallback: String {
        switch self {
        case .topUp: "充值"
        case .welcome: "开户赠送"
        case .activityPayment: "活动支付"
        case .activityRefund: "活动退款"
        case .bookingPayment: "陪玩支付"
        case .bookingRefund: "陪玩退款"
        case .transferOut: "转账支出"
        case .transferIn: "转账收款"
        case .transferRefund: "转账退回"
        case .membership: "会员开通"
        }
    }

    var systemImage: String {
        switch self {
        case .topUp, .welcome: "plus.circle.fill"
        case .activityPayment, .activityRefund: "calendar"
        case .bookingPayment, .bookingRefund: "person.2.fill"
        case .transferOut, .transferIn, .transferRefund: "yensign.circle.fill"
        case .membership: "checkmark.seal.fill"
        }
    }
}

struct WalletLedgerEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: WalletEntryKind
    let title: String
    var subtitle: String?
    /// 对余额的影响：支出为负、收入为正；外部支付可为 0
    let balanceDeltaCents: Int
    /// 业务金额（始终为正），用于展示
    let amountCents: Int
    let method: PaymentMethod
    let createdAt: Date
    var relatedID: UUID?

    var isCredit: Bool { balanceDeltaCents > 0 || (balanceDeltaCents == 0 && kind == .transferIn) }
}

enum PaymentOutcome: Equatable {
    case success
    case insufficientBalance
    case failed(String)
}

// MARK: - Store

@MainActor
@Observable
final class WalletStore {
    static let shared = WalletStore()

    private static let fileName = "wallet_ledger.json"
    private static let legacyBalanceKey = "profile.wallet.balanceCents"

    private(set) var balanceCents: Int
    private(set) var lifetimeTopUpCents: Int
    private(set) var entries: [WalletLedgerEntry]

    private init() {
        let snapshot = Self.load()
        let loadedEntries = snapshot.entries.sorted { $0.createdAt > $1.createdAt }
        let lifetime = snapshot.lifetimeTopUpCents
            ?? Self.recomputeLifetimeTopUp(from: loadedEntries)
        balanceCents = snapshot.balanceCents
        lifetimeTopUpCents = lifetime
        entries = loadedEntries
        migrateLegacyBalanceIfNeeded()
        seedWelcomeIfNeeded()
    }

    var balanceText: String { WalletMoney.formatted(cents: balanceCents) }

    var cardTier: WalletBankCardTier {
        WalletBankCardTier.resolve(lifetimeTopUpCents: lifetimeTopUpCents)
    }

    func canAfford(_ cents: Int) -> Bool {
        cents <= 0 || balanceCents >= cents
    }

    @discardableResult
    func charge(
        amountCents: Int,
        method: PaymentMethod,
        kind: WalletEntryKind,
        title: String,
        subtitle: String? = nil,
        relatedID: UUID? = nil
    ) -> PaymentOutcome {
        guard amountCents > 0 else { return .failed("金额无效") }
        if method.affectsWalletBalance {
            guard canAfford(amountCents) else { return .insufficientBalance }
            balanceCents -= amountCents
        }
        prepend(
            WalletLedgerEntry(
                id: UUID(),
                kind: kind,
                title: title,
                subtitle: subtitle,
                balanceDeltaCents: method.affectsWalletBalance ? -amountCents : 0,
                amountCents: amountCents,
                method: method,
                createdAt: .now,
                relatedID: relatedID
            )
        )
        persist()
        syncLegacyBalance()
        return .success
    }

    func credit(
        amountCents: Int,
        method: PaymentMethod,
        kind: WalletEntryKind,
        title: String,
        subtitle: String? = nil,
        relatedID: UUID? = nil
    ) {
        guard amountCents > 0 else { return }
        // 充值 / 转账收款始终入账；退款仅原支付方式为余额时加回；外部支付只记流水
        let appliedDelta: Int = {
            switch kind {
            case .topUp, .welcome, .transferIn:
                return amountCents
            case .activityRefund, .bookingRefund, .transferRefund:
                return method.affectsWalletBalance ? amountCents : 0
            default:
                return method.affectsWalletBalance ? amountCents : 0
            }
        }()
        if appliedDelta != 0 {
            balanceCents += appliedDelta
        }
        prepend(
            WalletLedgerEntry(
                id: UUID(),
                kind: kind,
                title: title,
                subtitle: subtitle,
                balanceDeltaCents: appliedDelta,
                amountCents: amountCents,
                method: method,
                createdAt: .now,
                relatedID: relatedID
            )
        )
        persist()
        syncLegacyBalance()
    }

    @discardableResult
    func topUp(amountCents: Int, method: PaymentMethod = .applePay) -> PaymentOutcome {
        guard amountCents > 0 else { return .failed("金额无效") }
        balanceCents += amountCents
        lifetimeTopUpCents += amountCents
        prepend(
            WalletLedgerEntry(
                id: UUID(),
                kind: .topUp,
                title: "充值",
                subtitle: method.displayName,
                balanceDeltaCents: amountCents,
                amountCents: amountCents,
                method: method,
                createdAt: .now,
                relatedID: nil
            )
        )
        persist()
        syncLegacyBalance()
        return .success
    }

    func entries(relatedTo id: UUID) -> [WalletLedgerEntry] {
        entries.filter { $0.relatedID == id }
    }

    /// 将最近一笔尚未关联业务 id 的同类型流水挂上 relatedID
    func attachRelatedID(_ relatedID: UUID, toKind kind: WalletEntryKind, amountCents: Int) {
        guard let index = entries.firstIndex(where: {
            $0.kind == kind && $0.relatedID == nil && $0.amountCents == amountCents
        }) else { return }
        entries[index].relatedID = relatedID
        persist()
    }

    func resetAll() {
        balanceCents = 0
        lifetimeTopUpCents = 0
        entries = []
        persist()
        seedWelcomeIfNeeded(force: true)
        syncLegacyBalance()
    }

    // MARK: Private

    private func prepend(_ entry: WalletLedgerEntry) {
        entries.insert(entry, at: 0)
    }

    private static func recomputeLifetimeTopUp(from entries: [WalletLedgerEntry]) -> Int {
        entries
            .filter { $0.kind == .topUp || $0.kind == .welcome }
            .reduce(0) { $0 + $1.amountCents }
    }

    private func seedWelcomeIfNeeded(force: Bool = false) {
        guard force || (entries.isEmpty && balanceCents == 0) else { return }
        let gift = 50_000
        balanceCents = gift
        lifetimeTopUpCents = gift
        prepend(
            WalletLedgerEntry(
                id: UUID(),
                kind: .welcome,
                title: "开户赠送",
                subtitle: "本地演示余额",
                balanceDeltaCents: gift,
                amountCents: gift,
                method: .wallet,
                createdAt: .now,
                relatedID: nil
            )
        )
        persist()
        syncLegacyBalance()
    }

    private func migrateLegacyBalanceIfNeeded() {
        let legacy = UserDefaults.standard.integer(forKey: Self.legacyBalanceKey)
        guard entries.isEmpty, balanceCents == 0, legacy > 0 else { return }
        balanceCents = legacy
        lifetimeTopUpCents = max(lifetimeTopUpCents, legacy)
        prepend(
            WalletLedgerEntry(
                id: UUID(),
                kind: .welcome,
                title: "余额迁移",
                subtitle: "自旧版钱包",
                balanceDeltaCents: legacy,
                amountCents: legacy,
                method: .wallet,
                createdAt: .now,
                relatedID: nil
            )
        )
        persist()
    }

    private func syncLegacyBalance() {
        UserDefaults.standard.set(balanceCents, forKey: Self.legacyBalanceKey)
    }

    private struct Snapshot: Codable {
        var balanceCents: Int
        var lifetimeTopUpCents: Int?
        var entries: [WalletLedgerEntry]
    }

    private static func load() -> Snapshot {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Snapshot.self, from: data)
        else {
            return Snapshot(balanceCents: 0, lifetimeTopUpCents: 0, entries: [])
        }
        return decoded
    }

    private func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.fileName)
        let snapshot = Snapshot(
            balanceCents: balanceCents,
            lifetimeTopUpCents: lifetimeTopUpCents,
            entries: entries
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}

// MARK: - Shared checkout sheet

struct CoordinatePaymentSheet: View {
    let navigationTitle: String
    let summary: [(label: String, value: String)]
    let amountCents: Int
    var footer: String = "本地演示支付，不会产生真实扣款。"
    var preferredMethod: PaymentMethod = .wallet
    var onConfirm: (PaymentMethod) -> PaymentOutcome
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
        footer: String = "本地演示支付，不会产生真实扣款。",
        preferredMethod: PaymentMethod = .wallet,
        onConfirm: @escaping (PaymentMethod) -> PaymentOutcome,
        onCancel: @escaping () -> Void = {}
    ) {
        self.navigationTitle = navigationTitle
        self.summary = summary
        self.amountCents = amountCents
        self.footer = footer
        self.preferredMethod = preferredMethod
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _selectedMethod = State(initialValue: preferredMethod)
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
                        ForEach(PaymentMethod.allCases) { method in
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
        if selectedMethod == .wallet, !wallet.canAfford(amountCents) {
            errorMessage = "余额不足，请充值或改用其他支付方式。"
            return
        }
        isProcessing = true
        paymentTask?.cancel()
        paymentTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            let outcome = onConfirm(selectedMethod)
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
