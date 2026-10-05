//
//  WalletPayment.swift
//  坐标系
//
//  统一支付账本 Store（活动 / 陪玩 / 转账 / 充值）。
//

import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateModels
import Foundation
import Observation

@MainActor
@Observable
final class WalletStore {
    static var shared: WalletStore { AppComposition.walletStore }

    static let fileName = "wallet_ledger.json"
    static let legacyBalanceKey = "profile.wallet.balanceCents"

    let chargeUseCase = ChargeWalletUseCase()
    let creditUseCase = ApplyWalletCreditUseCase()

    /// 跨文件扩展（`+Remote` / `+Persistence`）会写入，故非 `private(set)`。
    var balanceCents: Int
    var lifetimeTopUpCents: Int
    var entries: [WalletLedgerEntry]

    init() {
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
        let evaluation = chargeUseCase.evaluate(
            balanceCents: balanceCents,
            amountCents: amountCents,
            methodAffectsBalance: method.affectsWalletBalance,
            isExternalMethod: method != .wallet,
            allowsSimulatedExternal: CommercePaymentPolicy.allowsSimulatedExternalCheckout
        )
        switch evaluation {
        case .failure(.invalidAmount):
            return .failed("金额无效")
        case .failure(.externalUnavailable):
            CommerceAnalytics.checkoutBlocked(method: method.rawValue)
            return .failed(CommercePaymentPolicy.externalCheckoutUnavailableMessage)
        case .failure(.insufficientBalance):
            return .insufficientBalance
        case .success(let newBalance, let balanceDelta):
            balanceCents = newBalance
            prepend(
                WalletLedgerEntry(
                    id: UUID(),
                    kind: kind,
                    title: title,
                    subtitle: subtitle,
                    balanceDeltaCents: balanceDelta,
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
    }

    /// 远程优先扣款：`useRemoteWallet` 时先打 charges，成功后以服务端余额/流水为准投影本地。
    func chargeAsync(
        amountCents: Int,
        method: PaymentMethod,
        kind: WalletEntryKind,
        title: String,
        subtitle: String? = nil,
        relatedID: UUID? = nil,
        orderType: String
    ) async -> PaymentOutcome {
        if FeatureFlags.useRemoteWallet, method.affectsWalletBalance, let relatedID {
            do {
                let result = try await RemoteWalletClient.charge(
                    amountCents: amountCents,
                    orderType: orderType,
                    orderID: relatedID
                )
                await projectRemoteAccount(
                    result.account,
                    fallback: WalletLedgerEntry(
                        id: result.ledgerEntryID ?? UUID(),
                        kind: kind,
                        title: title,
                        subtitle: subtitle,
                        balanceDeltaCents: -amountCents,
                        amountCents: amountCents,
                        method: .wallet,
                        createdAt: .now,
                        relatedID: relatedID
                    )
                )
                CommerceAnalytics.chargeResult(
                    orderType: orderType,
                    result: "success",
                    method: method.rawValue
                )
                return .success
            } catch {
                CommerceAnalytics.chargeResult(
                    orderType: orderType,
                    result: "failed",
                    method: method.rawValue
                )
                return .failed(
                    (error as? LocalizedError)?.errorDescription
                        ?? CommercePaymentPolicy.remoteWalletUnavailableMessage
                )
            }
        }
        let outcome = charge(
            amountCents: amountCents,
            method: method,
            kind: kind,
            title: title,
            subtitle: subtitle,
            relatedID: relatedID
        )
        let resultLabel: String = {
            switch outcome {
            case .success: "success_local"
            case .insufficientBalance: "insufficient"
            case .failed: "failed"
            }
        }()
        CommerceAnalytics.chargeResult(
            orderType: orderType,
            result: resultLabel,
            method: method.rawValue
        )
        return outcome
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
        let creditKind = Self.mapCreditKind(kind)
        let appliedDelta = creditUseCase.balanceDeltaCents(
            amountCents: amountCents,
            kind: creditKind,
            methodAffectsBalance: method.affectsWalletBalance
        )
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
        let evaluation = CreateWalletTopUpIntentUseCase().evaluate(
            amountCents: amountCents,
            channel: method.rawValue,
            allowsRemoteTopUp: false,
            allowsDemoTopUp: CommercePaymentPolicy.allowsSimulatedExternalCheckout,
            youthBlocked: false
        )
        guard case .ready = evaluation else {
            return .failed(CommercePaymentPolicy.externalCheckoutUnavailableMessage)
        }
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

    /// 远程充值：创建意图 → 轮询到账 → 拉取账户投影。未确认成功绝不本地加款。
    func topUpAsync(amountCents: Int, method: PaymentMethod) async -> PaymentOutcome {
        let evaluation = CreateWalletTopUpIntentUseCase().evaluate(
            amountCents: amountCents,
            channel: method.rawValue,
            allowsRemoteTopUp: CommercePaymentPolicy.allowsRemoteWallet,
            allowsDemoTopUp: CommercePaymentPolicy.allowsSimulatedExternalCheckout,
            youthBlocked: YouthModePreference.isEnabled
        )
        switch evaluation {
        case .failure(.youthBlocked):
            return .failed(CommerceAccessCopy.youthCommerceReason)
        case .failure(.invalidAmount):
            return .failed("金额无效")
        case .failure(.channelUnavailable):
            return .failed(RemoteWalletError.channelUnavailable.localizedDescription)
        case .failure(.remoteDisabled):
            return .failed(CommercePaymentPolicy.externalCheckoutUnavailableMessage)
        case .ready(let cents, let channel):
            if CommercePaymentPolicy.allowsSimulatedExternalCheckout,
               !CommercePaymentPolicy.allowsRemoteWallet {
                CommerceAnalytics.topUpStart(
                    channel: channel,
                    amountCents: cents,
                    mode: "demo_local"
                )
                let outcome = topUp(amountCents: cents, method: method)
                CommerceAnalytics.topUpResult(
                    channel: channel,
                    result: outcome == .success ? "success_demo" : "failed"
                )
                return outcome
            }
            CommerceAnalytics.topUpStart(
                channel: channel,
                amountCents: cents,
                mode: "remote"
            )
            do {
                let intent = try await RemoteWalletClient.createTopUp(
                    amountCents: cents,
                    channel: channel
                )
                _ = try await RemoteWalletClient.awaitTopUpCredit(id: intent.id)
                let account = try await RemoteWalletClient.fetchAccount()
                lifetimeTopUpCents += cents
                await projectRemoteAccount(
                    account,
                    fallback: WalletLedgerEntry(
                        id: intent.id,
                        kind: .topUp,
                        title: "充值",
                        subtitle: method.displayName,
                        balanceDeltaCents: cents,
                        amountCents: cents,
                        method: method,
                        createdAt: .now,
                        relatedID: intent.id
                    )
                )
                CommerceAnalytics.topUpResult(channel: channel, result: "success")
                return .success
            } catch {
                CommerceAnalytics.topUpResult(channel: channel, result: "failed")
                return .failed(
                    (error as? LocalizedError)?.errorDescription
                        ?? CommercePaymentPolicy.remoteWalletUnavailableMessage
                )
            }
        }
    }
}
