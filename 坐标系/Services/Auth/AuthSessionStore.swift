//
//  AuthSessionStore.swift
//  坐标系
//
//  登录会话元数据整份存 Keychain（Apple：敏感会话勿长期落 UserDefaults）。
//

import Foundation

/// 可持久化的登录会话快照（不含 JWT；JWT 见 `AuthTokenStore`）。
struct AuthSessionSnapshot: Codable, Equatable, Sendable {
    var isSignedIn: Bool
    var provider: LocalAccountProvider
    var phoneNumber: String

    static let signedOut = AuthSessionSnapshot(
        isSignedIn: false,
        provider: .phone,
        phoneNumber: ""
    )
}

protocol AuthSessionPersisting: Sendable {
    func load() -> AuthSessionSnapshot
    func save(_ snapshot: AuthSessionSnapshot)
    func clear()
}

/// Keychain 实现；`service` 可在测试中覆盖以免污染主 App 项。
struct KeychainAuthSessionStore: AuthSessionPersisting {
    private let account = "auth.session.snapshot"
    private let service: String

    private enum LegacyDefaults {
        static let signedIn = "auth.isSignedIn"
        static let phone = "auth.phone"
        static let guest = "auth.isGuest"
        static let provider = "auth.provider"
    }

    init(service: String = Bundle.main.bundleIdentifier ?? "app.zuobiaoxi.coordinate") {
        self.service = service
    }

    func load() -> AuthSessionSnapshot {
        if let raw = KeychainStore.string(account: account, service: service),
           let data = raw.data(using: .utf8),
           let snapshot = try? JSONDecoder().decode(AuthSessionSnapshot.self, from: data) {
            purgeLegacyDefaults()
            return normalize(snapshot)
        }

        let migrated = migrateLegacyDefaultsIfNeeded()
        purgeLegacyDefaults()
        if migrated.isSignedIn {
            save(migrated)
        }
        return migrated
    }

    func save(_ snapshot: AuthSessionSnapshot) {
        let normalized = normalize(snapshot)
        guard let data = try? JSONEncoder().encode(normalized),
              let raw = String(data: data, encoding: .utf8)
        else { return }
        try? KeychainStore.set(raw, account: account, service: service)
        purgeLegacyDefaults()
    }

    func clear() {
        KeychainStore.remove(account: account, service: service)
        purgeLegacyDefaults()
    }

    // MARK: - Private

    /// 旧访客会话一律视为未登录；清理脏 phone 占位。
    private func normalize(_ snapshot: AuthSessionSnapshot) -> AuthSessionSnapshot {
        var next = snapshot
        if next.provider == .guest || !next.isSignedIn {
            return .signedOut
        }
        // Apple / 微信登录也可绑定手机号；仅清理占位脏值。
        if next.phoneNumber.hasPrefix("apple.")
            || next.phoneNumber.hasPrefix("wechat.")
            || next.phoneNumber == "demo.apple"
            || next.phoneNumber == "demo.wechat" {
            next.phoneNumber = ""
        }
        return next
    }

    private func migrateLegacyDefaultsIfNeeded() -> AuthSessionSnapshot {
        let defaults = UserDefaults.standard
        let wasGuest = defaults.bool(forKey: LegacyDefaults.guest)
        let signedIn = defaults.bool(forKey: LegacyDefaults.signedIn)
        // 旧访客：丢弃登录态。
        if wasGuest || !signedIn {
            return .signedOut
        }
        let phone = defaults.string(forKey: LegacyDefaults.phone) ?? ""
        let provider: LocalAccountProvider
        if let raw = defaults.string(forKey: LegacyDefaults.provider),
           let stored = LocalAccountProvider(rawValue: raw),
           stored != .guest {
            provider = stored
        } else if phone.hasPrefix("apple.") || phone == "demo.apple" {
            provider = .apple
        } else if phone.hasPrefix("wechat.") || phone == "demo.wechat" {
            provider = .wechat
        } else {
            provider = .phone
        }
        return AuthSessionSnapshot(
            isSignedIn: true,
            provider: provider,
            phoneNumber: provider == .phone ? phone : ""
        )
    }

    private func purgeLegacyDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LegacyDefaults.signedIn)
        defaults.removeObject(forKey: LegacyDefaults.phone)
        defaults.removeObject(forKey: LegacyDefaults.guest)
        defaults.removeObject(forKey: LegacyDefaults.provider)
    }
}

/// 测试用内存实现。
final class InMemoryAuthSessionStore: AuthSessionPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var snapshot: AuthSessionSnapshot

    init(_ snapshot: AuthSessionSnapshot = .signedOut) {
        self.snapshot = snapshot
    }

    func load() -> AuthSessionSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshot
    }

    func save(_ snapshot: AuthSessionSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        self.snapshot = snapshot
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        snapshot = .signedOut
    }
}
