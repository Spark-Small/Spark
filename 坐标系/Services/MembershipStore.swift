//
//  MembershipStore.swift
//  坐标系
//
//  StoreKit 2：会员权益与 Transaction 监听。
//  购买 UI 由 SubscriptionStoreView 承担。
//

import Foundation
import Observation
import StoreKit
import CoordinateModels

@MainActor
@Observable
final class MembershipStore {
    static var shared: MembershipStore { AppComposition.membershipStore }

    static let monthlyProductID = "com.spark.membership.monthly"
    static let productIDs: Set<String> = [monthlyProductID]

    private(set) var isEntitled = false

    private var updatesTask: Task<Void, Never>?

    init() {
        isEntitled = UserDefaults.standard.bool(forKey: Self.entitlementKey)
    }

    private static let entitlementKey = "profile.membership.active"

    func startListeningForTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task { @MainActor [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(verification: update)
            }
        }
    }

    func refreshEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID) {
                entitled = true
                await transaction.finish()
            }
        }
        applyEntitlement(entitled)
    }

    private func handle(verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        if Self.productIDs.contains(transaction.productID) {
            applyEntitlement(true)
        }
        await transaction.finish()
    }

    private func applyEntitlement(_ value: Bool) {
        isEntitled = value
        UserDefaults.standard.set(value, forKey: Self.entitlementKey)
    }

    /// 演示路径：钱包扣款成功后本地开通（与 StoreKit 共用 entitlement 键）。
    /// 仅 DEBUG；Release 必须走 StoreKit Transaction。
    func applyDemoEntitlement() {
        #if DEBUG
        applyEntitlement(true)
        #endif
    }

    /// 退出登录时清除本机会员演示态（正式权益以 StoreKit / 服务端为准，下次启动会再校验）。
    func clearLocalEntitlement() {
        applyEntitlement(false)
    }
}
