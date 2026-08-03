//
//  PhotoVerificationStore.swift
//  坐标系
//
//  形象认证结果持久化（本机）。
//

import Foundation
import Observation

@MainActor
@Observable
final class PhotoVerificationStore {
    static let shared = PhotoVerificationStore()

    private static let verifiedKey = "photoVerification.verified"
    private static let verifiedAtKey = "photoVerification.verifiedAt"
    private static let similarityKey = "photoVerification.similarity"
    private static let userKeyKey = "photoVerification.userKey"

    private(set) var isVerified: Bool
    private(set) var verifiedAt: Date?
    private(set) var lastSimilarity: Double
    private(set) var boundUserKey: String?

    private init() {
        let defaults = UserDefaults.standard
        isVerified = defaults.bool(forKey: Self.verifiedKey)
        verifiedAt = defaults.object(forKey: Self.verifiedAtKey) as? Date
        lastSimilarity = defaults.double(forKey: Self.similarityKey)
        boundUserKey = defaults.string(forKey: Self.userKeyKey)
    }

    /// 当前登录用户是否已通过形象认证（游客 / 换号视为未通过）。
    func isVerified(for userKey: String) -> Bool {
        guard isVerified, let bound = boundUserKey else { return false }
        return bound.caseInsensitiveCompare(userKey) == .orderedSame
    }

    func markVerified(userKey: String, similarity: Double) {
        isVerified = true
        verifiedAt = .now
        lastSimilarity = similarity
        boundUserKey = userKey
        persist()
        TrustService.shared.bumpRevision()
    }

    func clear() {
        isVerified = false
        verifiedAt = nil
        lastSimilarity = 0
        boundUserKey = nil
        persist()
        TrustService.shared.bumpRevision()
    }

    func resetAll() {
        clear()
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(isVerified, forKey: Self.verifiedKey)
        defaults.set(verifiedAt, forKey: Self.verifiedAtKey)
        defaults.set(lastSimilarity, forKey: Self.similarityKey)
        defaults.set(boundUserKey, forKey: Self.userKeyKey)
    }
}
