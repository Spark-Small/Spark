//
//  MembershipStore.swift
//  坐标系
//
//  StoreKit 2 会员权益（无后端）：Transaction + 本机投影；DEBUG 可演示开通且不被刷新冲掉。
//

import Foundation
import Observation
import StoreKit

enum MembershipEntitlementSource: String, Sendable, Equatable {
    case none
    case storeKit
    case demoLocal
}

@MainActor
@Observable
final class MembershipStore {
    static var shared: MembershipStore { AppComposition.membershipStore }

    static let monthlyProductID = "com.spark.membership.monthly"
    static let productIDs: Set<String> = [monthlyProductID]
    /// 与 `StoreKit/Configuration.storekit` / App Store Connect 订阅组一致。
    static let subscriptionGroupID = "214E5F60"

    private static let storeKitEntitlementKey = "profile.membership.storekit"
    private static let demoEntitlementKey = "profile.membership.demo"
    /// 兼容旧键：曾把演示与 StoreKit 混写。
    private static let legacyEntitlementKey = "profile.membership.active"

    private(set) var storeKitEntitled = false
    private(set) var demoEntitled = false
    private(set) var activeProductID: String?
    private(set) var expirationDate: Date?
    private(set) var products: [Product] = []
    private(set) var productsLoadFailed = false
    private(set) var isRefreshing = false
    private(set) var lastRefreshedAt: Date?

    private var updatesTask: Task<Void, Never>?

    var isEntitled: Bool { storeKitEntitled || demoEntitled }

    var source: MembershipEntitlementSource {
        if storeKitEntitled { return .storeKit }
        if demoEntitled { return .demoLocal }
        return .none
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    init() {
        migrateLegacyEntitlementIfNeeded()
        storeKitEntitled = UserDefaults.standard.bool(forKey: Self.storeKitEntitlementKey)
        #if DEBUG
        demoEntitled = UserDefaults.standard.bool(forKey: Self.demoEntitlementKey)
        #else
        demoEntitled = false
        UserDefaults.standard.removeObject(forKey: Self.demoEntitlementKey)
        #endif
    }

    func startListeningForTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task { @MainActor [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(verification: update)
            }
        }
    }

    /// 拉取商品（无后端；依赖 StoreKit Configuration / App Store）。
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { $0.id < $1.id }
            productsLoadFailed = products.isEmpty
        } catch {
            products = []
            productsLoadFailed = true
        }
    }

    /// 与 App Store / 本地 Transaction 对账。DEBUG 演示权益在无 StoreKit 交易时保留。
    func refreshEntitlement() async {
        isRefreshing = true
        defer {
            isRefreshing = false
            lastRefreshedAt = .now
        }

        var entitled = false
        var productID: String?
        var expiration: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard Self.productIDs.contains(transaction.productID) else { continue }
            entitled = true
            productID = transaction.productID
            expiration = transaction.expirationDate
            await transaction.finish()
        }

        storeKitEntitled = entitled
        UserDefaults.standard.set(entitled, forKey: Self.storeKitEntitlementKey)

        if entitled {
            activeProductID = productID
            expirationDate = expiration
            #if DEBUG
            // StoreKit 真权益优先；清掉演示标记避免双源混淆
            if demoEntitled {
                demoEntitled = false
                UserDefaults.standard.set(false, forKey: Self.demoEntitlementKey)
            }
            #endif
        } else {
            activeProductID = nil
            expirationDate = nil
            #if DEBUG
            demoEntitled = UserDefaults.standard.bool(forKey: Self.demoEntitlementKey)
            #else
            demoEntitled = false
            #endif
        }

        // 兼容旧单一键：对外投影
        UserDefaults.standard.set(isEntitled, forKey: Self.legacyEntitlementKey)
    }

    /// 恢复购买：先 `AppStore.sync`，再刷权益与商品。
    func restorePurchases() async throws {
        try await AppStore.sync()
        await loadProducts()
        await refreshEntitlement()
    }

    private func handle(verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        if Self.productIDs.contains(transaction.productID) {
            storeKitEntitled = true
            activeProductID = transaction.productID
            expirationDate = transaction.expirationDate
            UserDefaults.standard.set(true, forKey: Self.storeKitEntitlementKey)
            UserDefaults.standard.set(true, forKey: Self.legacyEntitlementKey)
            #if DEBUG
            demoEntitled = false
            UserDefaults.standard.set(false, forKey: Self.demoEntitlementKey)
            #endif
        }
        await transaction.finish()
    }

    /// 仅 DEBUG：本机演示开通（不冒充 App Store 交易）。
    func applyDemoEntitlement() {
        #if DEBUG
        demoEntitled = true
        UserDefaults.standard.set(true, forKey: Self.demoEntitlementKey)
        UserDefaults.standard.set(true, forKey: Self.legacyEntitlementKey)
        activeProductID = Self.monthlyProductID
        expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: .now)
        #endif
    }

    /// 仅 DEBUG：关闭演示会员（不影响真 StoreKit 权益）。
    func clearDemoEntitlement() {
        #if DEBUG
        demoEntitled = false
        UserDefaults.standard.set(false, forKey: Self.demoEntitlementKey)
        if !storeKitEntitled {
            activeProductID = nil
            expirationDate = nil
            UserDefaults.standard.set(false, forKey: Self.legacyEntitlementKey)
        }
        #endif
    }

    /// 退出登录：清本机投影；下次启动以 StoreKit Transaction 为准。
    func clearLocalEntitlement() {
        storeKitEntitled = false
        demoEntitled = false
        activeProductID = nil
        expirationDate = nil
        products = []
        productsLoadFailed = false
        UserDefaults.standard.set(false, forKey: Self.storeKitEntitlementKey)
        UserDefaults.standard.set(false, forKey: Self.demoEntitlementKey)
        UserDefaults.standard.set(false, forKey: Self.legacyEntitlementKey)
    }

    private func migrateLegacyEntitlementIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Self.storeKitEntitlementKey) == nil,
              defaults.object(forKey: Self.demoEntitlementKey) == nil,
              defaults.bool(forKey: Self.legacyEntitlementKey)
        else { return }
        // 旧键无法区分来源：Release 视为待 StoreKit 复核；DEBUG 暂挂演示以免立刻丢态
        #if DEBUG
        defaults.set(true, forKey: Self.demoEntitlementKey)
        #endif
        defaults.set(false, forKey: Self.storeKitEntitlementKey)
    }
}
