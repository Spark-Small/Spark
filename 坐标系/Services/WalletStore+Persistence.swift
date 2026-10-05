//
//  WalletStore+Persistence.swift
//  坐标系
//
//  账本查询、清理与本地持久化。
//

import CoordinateDomain
import CoordinateModels
import Foundation

extension WalletStore {
    func entries(relatedTo id: UUID) -> [WalletLedgerEntry] {
        entries.filter { $0.relatedID == id }
    }

    /// 移除某业务相关流水（Debug 自检清理；退款场景勿用）
    func removeEntries(relatedTo id: UUID) {
        let removed = entries.filter { $0.relatedID == id }
        guard !removed.isEmpty else { return }
        for entry in removed {
            // 冲正曾计入余额的演示扣款 / 入账
            balanceCents -= entry.balanceDeltaCents
        }
        entries.removeAll { $0.relatedID == id }
        persist()
        syncLegacyBalance()
    }

    /// 清除 DEBUG 自检留下的「陪玩 · 阿凯」Apple Pay 空扣款（不影响余额）
    func purgeDebugSelfTestBookingCharges() {
        let title = SampleData.paidCompanions.first.map { "陪玩 · \($0.profile.nickname)" }
        let before = entries.count
        entries.removeAll { entry in
            entry.kind == .bookingPayment
                && entry.method == .applePay
                && entry.balanceDeltaCents == 0
                && (title == nil || entry.title == title)
        }
        guard entries.count != before else { return }
        persist()
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


    func prepend(_ entry: WalletLedgerEntry) {
        entries.insert(entry, at: 0)
    }

    static func recomputeLifetimeTopUp(from entries: [WalletLedgerEntry]) -> Int {
        entries
            .filter { $0.kind == .topUp || $0.kind == .welcome }
            .reduce(0) { $0 + $1.amountCents }
    }

    static func mapCreditKind(_ kind: WalletEntryKind) -> WalletCreditKind {
        switch kind {
        case .topUp: .topUp
        case .welcome: .welcome
        case .transferIn: .transferIn
        case .activityRefund: .activityRefund
        case .bookingRefund: .bookingRefund
        case .transferRefund: .transferRefund
        default: .other
        }
    }

    static func mapRemoteLedgerItem(_ dto: WalletLedgerItemDTO) -> WalletLedgerEntry {
        let kind = WalletEntryKind.resolve(dto.kind)
        let method = PaymentMethod.resolve(dto.channel ?? "wallet")
        let subtitle: String? = {
            guard let channel = dto.channel, !channel.isEmpty else { return nil }
            return PaymentMethod.resolve(channel).displayName
        }()
        return WalletLedgerEntry(
            id: dto.id,
            kind: kind,
            title: dto.title.isEmpty ? kind.titleFallback : dto.title,
            subtitle: subtitle,
            balanceDeltaCents: dto.deltaCents,
            amountCents: max(dto.amountCents, abs(dto.deltaCents)),
            method: method,
            createdAt: dto.createdAt,
            relatedID: dto.relatedID
        )
    }

    func seedWelcomeIfNeeded(force: Bool = false) {
        #if DEBUG
        let gift = WalletMoneyPolicy.welcomeGiftCents(isDebugBuild: true)
        guard gift > 0 else { return }
        guard force || (entries.isEmpty && balanceCents == 0) else { return }
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
        #else
        _ = force
        // Release：欢迎金为 0，不写入假充值流水
        #endif
    }

    func migrateLegacyBalanceIfNeeded() {
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

    func syncLegacyBalance() {
        UserDefaults.standard.set(balanceCents, forKey: Self.legacyBalanceKey)
    }

    struct Snapshot: Codable {
        var balanceCents: Int
        var lifetimeTopUpCents: Int?
        var entries: [WalletLedgerEntry]
    }

    static func load() -> Snapshot {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Snapshot.self, from: data)
        else {
            return Snapshot(balanceCents: 0, lifetimeTopUpCents: 0, entries: [])
        }
        return decoded
    }

    func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.fileName)
        let snapshot = Snapshot(
            balanceCents: balanceCents,
            lifetimeTopUpCents: lifetimeTopUpCents,
            entries: entries
        )
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: [.atomic])
        } catch {
            assertionFailure("Wallet persist failed: \(error)")
            PersistenceWriteFailureReporter.record(domainKey: "wallet", error: error)
        }
    }
}
