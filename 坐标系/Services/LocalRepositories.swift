//
//  LocalRepositories.swift
//  坐标系
//

import Foundation

enum LocalPersistenceKey: Hashable {
    case activities
    case messages
    case buddies
    case community
    case profile
}

enum LocalPersistenceCoordinator {
    private static let lock = NSLock()
    private static var generations: [LocalPersistenceKey: Int] = [:]

    static func currentGeneration(for key: LocalPersistenceKey) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return generations[key, default: 0]
    }

    @discardableResult
    static func invalidate(_ key: LocalPersistenceKey) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let next = generations[key, default: 0] + 1
        generations[key] = next
        return next
    }

    static func invalidate(_ keys: [LocalPersistenceKey]) {
        lock.lock()
        defer { lock.unlock() }
        for key in keys {
            generations[key] = generations[key, default: 0] + 1
        }
    }

    static func isCurrent(_ generation: Int, for key: LocalPersistenceKey) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return generations[key, default: 0] == generation
    }
}

protocol ActivitiesRepository {
    var persistenceKey: LocalPersistenceKey { get }
    func load() -> ActivitiesSnapshot
    func save(_ snapshot: ActivitiesSnapshot)
}

extension ActivitiesRepository {
    func replace(with snapshot: ActivitiesSnapshot) {
        save(snapshot)
    }

    func loadAsync() async throws -> ActivitiesSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: load())
            }
        }
    }

    func saveAsync(_ snapshot: ActivitiesSnapshot) async throws {
        let generation = currentPersistenceGeneration()
        try await saveAsync(snapshot, generation: generation)
    }

    func saveAsync(_ snapshot: ActivitiesSnapshot, generation: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .utility).async {
                guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                save(snapshot)
                continuation.resume()
            }
        }
    }

    func replaceAsync(with snapshot: ActivitiesSnapshot) async throws {
        try await saveAsync(snapshot)
    }

    func replaceAsync(with snapshot: ActivitiesSnapshot, generation: Int) async throws {
        try await saveAsync(snapshot, generation: generation)
    }

    func mutate(_ mutate: (inout ActivitiesSnapshot) -> Void) {
        var snapshot = load()
        mutate(&snapshot)
        save(snapshot)
    }

    func mutateAsync(_ mutate: @escaping (inout ActivitiesSnapshot) -> Void) async throws {
        var snapshot = try await loadAsync()
        mutate(&snapshot)
        try await saveAsync(snapshot)
    }

    func currentPersistenceGeneration() -> Int {
        LocalPersistenceCoordinator.currentGeneration(for: persistenceKey)
    }

    func invalidatePendingWrites() {
        LocalPersistenceCoordinator.invalidate(persistenceKey)
    }
}

protocol MessagesRepository {
    var persistenceKey: LocalPersistenceKey { get }
    func load() -> MessagesSnapshot
    func save(_ snapshot: MessagesSnapshot)
}

extension MessagesRepository {
    func replace(with snapshot: MessagesSnapshot) {
        save(snapshot)
    }

    func loadAsync() async throws -> MessagesSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: load())
            }
        }
    }

    func saveAsync(_ snapshot: MessagesSnapshot) async throws {
        let generation = currentPersistenceGeneration()
        try await saveAsync(snapshot, generation: generation)
    }

    func saveAsync(_ snapshot: MessagesSnapshot, generation: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .utility).async {
                guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                save(snapshot)
                continuation.resume()
            }
        }
    }

    func replaceAsync(with snapshot: MessagesSnapshot) async throws {
        try await saveAsync(snapshot)
    }

    func replaceAsync(with snapshot: MessagesSnapshot, generation: Int) async throws {
        try await saveAsync(snapshot, generation: generation)
    }

    func mutate(_ mutate: (inout MessagesSnapshot) -> Void) {
        var snapshot = load()
        mutate(&snapshot)
        save(snapshot)
    }

    func mutateAsync(_ mutate: @escaping (inout MessagesSnapshot) -> Void) async throws {
        var snapshot = try await loadAsync()
        mutate(&snapshot)
        try await saveAsync(snapshot)
    }

    func currentPersistenceGeneration() -> Int {
        LocalPersistenceCoordinator.currentGeneration(for: persistenceKey)
    }

    func invalidatePendingWrites() {
        LocalPersistenceCoordinator.invalidate(persistenceKey)
    }
}

protocol BuddiesRepository {
    var persistenceKey: LocalPersistenceKey { get }
    func load() -> BuddiesSnapshot
    func save(_ snapshot: BuddiesSnapshot)
}

extension BuddiesRepository {
    func replace(with snapshot: BuddiesSnapshot) {
        save(snapshot)
    }

    func loadAsync() async throws -> BuddiesSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: load())
            }
        }
    }

    func saveAsync(_ snapshot: BuddiesSnapshot) async throws {
        let generation = currentPersistenceGeneration()
        try await saveAsync(snapshot, generation: generation)
    }

    func saveAsync(_ snapshot: BuddiesSnapshot, generation: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .utility).async {
                guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                save(snapshot)
                continuation.resume()
            }
        }
    }

    func replaceAsync(with snapshot: BuddiesSnapshot) async throws {
        try await saveAsync(snapshot)
    }

    func replaceAsync(with snapshot: BuddiesSnapshot, generation: Int) async throws {
        try await saveAsync(snapshot, generation: generation)
    }

    func mutate(_ mutate: (inout BuddiesSnapshot) -> Void) {
        var snapshot = load()
        mutate(&snapshot)
        save(snapshot)
    }

    func mutateAsync(_ mutate: @escaping (inout BuddiesSnapshot) -> Void) async throws {
        var snapshot = try await loadAsync()
        mutate(&snapshot)
        try await saveAsync(snapshot)
    }

    func currentPersistenceGeneration() -> Int {
        LocalPersistenceCoordinator.currentGeneration(for: persistenceKey)
    }

    func invalidatePendingWrites() {
        LocalPersistenceCoordinator.invalidate(persistenceKey)
    }
}

protocol CommunityRepository {
    var persistenceKey: LocalPersistenceKey { get }
    func load() -> CommunitySnapshot
    func save(_ snapshot: CommunitySnapshot)
}

extension CommunityRepository {
    func replace(with snapshot: CommunitySnapshot) {
        save(snapshot)
    }

    func loadAsync() async throws -> CommunitySnapshot {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: load())
            }
        }
    }

    func saveAsync(_ snapshot: CommunitySnapshot) async throws {
        let generation = currentPersistenceGeneration()
        try await saveAsync(snapshot, generation: generation)
    }

    func saveAsync(_ snapshot: CommunitySnapshot, generation: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .utility).async {
                guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                save(snapshot)
                continuation.resume()
            }
        }
    }

    func replaceAsync(with snapshot: CommunitySnapshot) async throws {
        try await saveAsync(snapshot)
    }

    func replaceAsync(with snapshot: CommunitySnapshot, generation: Int) async throws {
        try await saveAsync(snapshot, generation: generation)
    }

    func mutate(_ mutate: (inout CommunitySnapshot) -> Void) {
        var snapshot = load()
        mutate(&snapshot)
        save(snapshot)
    }

    func mutateAsync(_ mutate: @escaping (inout CommunitySnapshot) -> Void) async throws {
        var snapshot = try await loadAsync()
        mutate(&snapshot)
        try await saveAsync(snapshot)
    }

    func currentPersistenceGeneration() -> Int {
        LocalPersistenceCoordinator.currentGeneration(for: persistenceKey)
    }

    func invalidatePendingWrites() {
        LocalPersistenceCoordinator.invalidate(persistenceKey)
    }
}

protocol ProfileRepository {
    var persistenceKey: LocalPersistenceKey { get }
    func load() -> ProfileSnapshot
    func save(_ snapshot: ProfileSnapshot)
}

extension ProfileRepository {
    func replace(with snapshot: ProfileSnapshot) {
        save(snapshot)
    }

    func loadAsync() async throws -> ProfileSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: load())
            }
        }
    }

    func saveAsync(_ snapshot: ProfileSnapshot) async throws {
        let generation = currentPersistenceGeneration()
        try await saveAsync(snapshot, generation: generation)
    }

    func saveAsync(_ snapshot: ProfileSnapshot, generation: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .utility).async {
                guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                save(snapshot)
                continuation.resume()
            }
        }
    }

    func replaceAsync(with snapshot: ProfileSnapshot) async throws {
        try await saveAsync(snapshot)
    }

    func replaceAsync(with snapshot: ProfileSnapshot, generation: Int) async throws {
        try await saveAsync(snapshot, generation: generation)
    }

    func mutate(_ mutate: (inout ProfileSnapshot) -> Void) {
        var snapshot = load()
        mutate(&snapshot)
        save(snapshot)
    }

    func mutateAsync(_ mutate: @escaping (inout ProfileSnapshot) -> Void) async throws {
        var snapshot = try await loadAsync()
        mutate(&snapshot)
        try await saveAsync(snapshot)
    }

    func currentPersistenceGeneration() -> Int {
        LocalPersistenceCoordinator.currentGeneration(for: persistenceKey)
    }

    func invalidatePendingWrites() {
        LocalPersistenceCoordinator.invalidate(persistenceKey)
    }
}

struct LocalActivitiesRepository: ActivitiesRepository {
    /// 默认 MainActor 隔离下，供 Model 默认参数 / 初始化安全调用
    nonisolated init() {}
    let persistenceKey: LocalPersistenceKey = .activities
    func load() -> ActivitiesSnapshot { AppPersistence.loadActivities() }
    func save(_ snapshot: ActivitiesSnapshot) { AppPersistence.saveActivities(snapshot) }
}

struct LocalMessagesRepository: MessagesRepository {
    nonisolated init() {}
    let persistenceKey: LocalPersistenceKey = .messages
    func load() -> MessagesSnapshot { AppPersistence.loadMessages() }
    func save(_ snapshot: MessagesSnapshot) { AppPersistence.saveMessages(snapshot) }
}

struct LocalBuddiesRepository: BuddiesRepository {
    nonisolated init() {}
    let persistenceKey: LocalPersistenceKey = .buddies
    func load() -> BuddiesSnapshot { AppPersistence.loadBuddies() }
    func save(_ snapshot: BuddiesSnapshot) { AppPersistence.saveBuddies(snapshot) }
}

struct LocalCommunityRepository: CommunityRepository {
    nonisolated init() {}
    let persistenceKey: LocalPersistenceKey = .community
    func load() -> CommunitySnapshot { CommunityPersistence.load() }
    func save(_ snapshot: CommunitySnapshot) { CommunityPersistence.save(snapshot) }
}

struct LocalProfileRepository: ProfileRepository {
    nonisolated init() {}
    let persistenceKey: LocalPersistenceKey = .profile
    func load() -> ProfileSnapshot { AppPersistence.loadProfile() }
    func save(_ snapshot: ProfileSnapshot) { AppPersistence.saveProfile(snapshot) }
}

/// 单测 / DEBUG 自检用，避免污染本机 JSON
final class InMemoryActivitiesRepository: ActivitiesRepository {
    let persistenceKey: LocalPersistenceKey = .activities
    var snapshot: ActivitiesSnapshot
    init(snapshot: ActivitiesSnapshot) { self.snapshot = snapshot }
    func load() -> ActivitiesSnapshot { snapshot }
    func save(_ snapshot: ActivitiesSnapshot) { self.snapshot = snapshot }
}

final class InMemoryMessagesRepository: MessagesRepository {
    let persistenceKey: LocalPersistenceKey = .messages
    var snapshot: MessagesSnapshot
    init(snapshot: MessagesSnapshot) { self.snapshot = snapshot }
    func load() -> MessagesSnapshot { snapshot }
    func save(_ snapshot: MessagesSnapshot) { self.snapshot = snapshot }
}

final class InMemoryBuddiesRepository: BuddiesRepository {
    let persistenceKey: LocalPersistenceKey = .buddies
    var snapshot: BuddiesSnapshot
    init(snapshot: BuddiesSnapshot) { self.snapshot = snapshot }
    func load() -> BuddiesSnapshot { snapshot }
    func save(_ snapshot: BuddiesSnapshot) { self.snapshot = snapshot }
}

final class InMemoryProfileRepository: ProfileRepository {
    let persistenceKey: LocalPersistenceKey = .profile
    var snapshot: ProfileSnapshot
    init(snapshot: ProfileSnapshot) { self.snapshot = snapshot }
    func load() -> ProfileSnapshot { snapshot }
    func save(_ snapshot: ProfileSnapshot) { self.snapshot = snapshot }
}

enum RecommendationConfig {
    /// 「附近」阈值（km）
    static var nearbyKM: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "reco.nearbyKM")
            return v > 0 ? v : 3
        }
        set { UserDefaults.standard.set(newValue, forKey: "reco.nearbyKM") }
    }

    /// 「即将开始」窗口（小时）
    static var startingSoonHours: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "reco.startingSoonHours")
            return v > 0 ? v : 48
        }
        set { UserDefaults.standard.set(newValue, forKey: "reco.startingSoonHours") }
    }
}

enum MatchWeights {
    static var sharedHobby: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "match.sharedHobby")
            return v > 0 ? v : 30
        }
        set { UserDefaults.standard.set(newValue, forKey: "match.sharedHobby") }
    }

    static var availableBonus: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "match.availableBonus")
            return v > 0 ? v : 20
        }
        set { UserDefaults.standard.set(newValue, forKey: "match.availableBonus") }
    }

    static var onlineBonus: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "match.onlineBonus")
            return v > 0 ? v : 10
        }
        set { UserDefaults.standard.set(newValue, forKey: "match.onlineBonus") }
    }
}

enum ContentModeration {
    static let sensitiveWords = ["赌博", "色情", "毒品", "诈骗", "加微信刷单"]

    static func containsSensitive(_ text: String) -> String? {
        for word in sensitiveWords where text.localizedCaseInsensitiveContains(word) {
            return word
        }
        return nil
    }
}
