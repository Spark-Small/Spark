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

@MainActor
@Observable
final class MembershipStore {
    static let shared = MembershipStore()

    static let monthlyProductID = "com.spark.membership.monthly"
    static let productIDs: Set<String> = [monthlyProductID]

    private(set) var isEntitled = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        isEntitled = UserDefaults.standard.bool(forKey: Self.entitlementKey)
    }

    private static let entitlementKey = "profile.membership.active"

    func startListeningForTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
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
}
