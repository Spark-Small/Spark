//
//  PhotoVerificationStore.swift
//  坐标系
//
//  形象认证结果持久化（本机）：绑定用户 + 认证照基准指纹 + 冷却 / 联网复核。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class PhotoVerificationStore {
    static var shared: PhotoVerificationStore { AppComposition.photoVerificationStore }

    private static let verifiedKey = "photoVerification.verified"
    private static let verifiedAtKey = "photoVerification.verifiedAt"
    private static let similarityKey = "photoVerification.similarity"
    private static let userKeyKey = "photoVerification.userKey"
    private static let baselineKey = "photoVerification.baseline"
    private static let remoteVerifiedKey = "photoVerification.remoteVerified"
    private static let failureCountKey = "photoVerification.failureCount"
    private static let cooldownUntilKey = "photoVerification.cooldownUntil"

    static let maxFailuresBeforeCooldown = 3
    static let cooldownDuration: TimeInterval = 15 * 60

    private let trustService: TrustService

    private(set) var isVerified: Bool
    private(set) var verifiedAt: Date?
    private(set) var lastSimilarity: Double
    private(set) var boundUserKey: String?
    private(set) var baselineFingerprint: String?
    private(set) var remoteVerified: Bool
    private(set) var consecutiveFailures: Int
    private(set) var cooldownUntil: Date?

    init(trustService: TrustService) {
        self.trustService = trustService
        let defaults = UserDefaults.standard
        isVerified = defaults.bool(forKey: Self.verifiedKey)
        verifiedAt = defaults.object(forKey: Self.verifiedAtKey) as? Date
        lastSimilarity = defaults.double(forKey: Self.similarityKey)
        boundUserKey = defaults.string(forKey: Self.userKeyKey)
        baselineFingerprint = defaults.string(forKey: Self.baselineKey)
        remoteVerified = defaults.bool(forKey: Self.remoteVerifiedKey)
        consecutiveFailures = defaults.integer(forKey: Self.failureCountKey)
        cooldownUntil = defaults.object(forKey: Self.cooldownUntilKey) as? Date
    }

    var isInCooldown: Bool {
        guard let cooldownUntil else { return false }
        return cooldownUntil > .now
    }

    var cooldownRemainingText: String? {
        guard let cooldownUntil, cooldownUntil > .now else { return nil }
        let seconds = Int(cooldownUntil.timeIntervalSinceNow.rounded(.up))
        let minutes = max(1, (seconds + 59) / 60)
        return "请 \(minutes) 分钟后再试"
    }

    /// 当前登录用户是否已通过形象认证（游客 / 换号 / 认证照变更视为未通过）。
    func isVerified(for userKey: String, photos: [VerificationPhoto] = []) -> Bool {
        guard isVerified, let bound = boundUserKey else { return false }
        guard bound.caseInsensitiveCompare(userKey) == .orderedSame else { return false }
        guard VerificationPhotoLimits.isReady(photos) else { return false }
        let fingerprint = VerificationPhotoLimits.baselineFingerprint(for: photos)
        guard let baselineFingerprint, baselineFingerprint == fingerprint else { return false }
        return true
    }

    func isVerified(for user: AppUser) -> Bool {
        isVerified(for: user.name, photos: user.verificationPhotos)
    }

    func markVerified(
        userKey: String,
        similarity: Double,
        photos: [VerificationPhoto],
        remoteVerified: Bool
    ) {
        guard VerificationPhotoLimits.isReady(photos) else { return }
        isVerified = true
        verifiedAt = .now
        lastSimilarity = similarity
        boundUserKey = userKey
        baselineFingerprint = VerificationPhotoLimits.baselineFingerprint(for: photos)
        self.remoteVerified = remoteVerified
        consecutiveFailures = 0
        cooldownUntil = nil
        persist()
        trustService.bumpRevision()
    }

    func recordFailure(userKey: String) {
        consecutiveFailures += 1
        if consecutiveFailures >= Self.maxFailuresBeforeCooldown {
            cooldownUntil = Date().addingTimeInterval(Self.cooldownDuration)
        }
        persist()
        trustService.record(
            .identityFailed,
            domain: .moderation,
            actorKey: userKey,
            value: Double(consecutiveFailures),
            note: isInCooldown ? "cooldown" : "retry"
        )
        trustService.bumpRevision()
    }

    /// 认证照基准变更时撤证（仅改 isPublic 不应调用）。
    func invalidateIfBaselineChanged(photos: [VerificationPhoto]) {
        let fingerprint = VerificationPhotoLimits.baselineFingerprint(for: photos)
        guard let baselineFingerprint else { return }
        if baselineFingerprint != fingerprint {
            clear()
        }
    }

    func clear() {
        isVerified = false
        verifiedAt = nil
        lastSimilarity = 0
        boundUserKey = nil
        baselineFingerprint = nil
        remoteVerified = false
        persist()
        trustService.bumpRevision()
    }

    func resetAll() {
        consecutiveFailures = 0
        cooldownUntil = nil
        clear()
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(isVerified, forKey: Self.verifiedKey)
        defaults.set(verifiedAt, forKey: Self.verifiedAtKey)
        defaults.set(lastSimilarity, forKey: Self.similarityKey)
        defaults.set(boundUserKey, forKey: Self.userKeyKey)
        defaults.set(baselineFingerprint, forKey: Self.baselineKey)
        defaults.set(remoteVerified, forKey: Self.remoteVerifiedKey)
        defaults.set(consecutiveFailures, forKey: Self.failureCountKey)
        defaults.set(cooldownUntil, forKey: Self.cooldownUntilKey)
    }
}
