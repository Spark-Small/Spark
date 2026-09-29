//
//  IdentityRemoteReverifyService.swift
//  坐标系
//
//  本机比对通过后的联网 / 演示代理二次复核。青少年模式不上云特征。
//

import CryptoKit
import CoordinateFeatureFlags
import CoordinateNetworking
import Foundation
import UIKit

enum IdentityRemoteReverifyService {
    struct Outcome: Sendable {
        var passed: Bool
        var remoteScore: Double
        var reason: String?
        var usedNetwork: Bool
    }

    /// 青少年模式：仅本机更严复核，不上传特征。
    static func reverify(
        userKey: String,
        baselineFingerprint: String,
        localSimilarity: Double,
        capture: UIImage,
        youthMode: Bool
    ) async -> Outcome {
        guard FeatureFlags.useRemoteIdentityReverify else {
            return Outcome(passed: true, remoteScore: localSimilarity, reason: nil, usedNetwork: false)
        }

        let digest = featureDigest(for: capture, similarity: localSimilarity)

        if youthMode || FeatureFlags.useDemoIdentityReverifyProxy {
            let threshold = youthMode ? 0.80 : 0.76
            let passed = localSimilarity >= threshold
            return Outcome(
                passed: passed,
                remoteScore: localSimilarity,
                reason: passed ? nil : "二次复核未通过，请换光线充足的环境重拍。",
                usedNetwork: false
            )
        }

        do {
            let body = IdentityReverifyRequest(
                userKey: userKey,
                baselineFingerprint: baselineFingerprint,
                localSimilarity: localSimilarity,
                featureDigest: digest,
                youthMode: youthMode
            )
            let response = try await APIClient.shared.send(.reverifyIdentity(body))
            return Outcome(
                passed: response.passed,
                remoteScore: response.remoteScore,
                reason: response.reason,
                usedNetwork: true
            )
        } catch {
            // 联网失败：演示默认放行本机结果；正式可改为拦截
            return Outcome(
                passed: true,
                remoteScore: localSimilarity,
                reason: "复核服务暂不可用，已采用本机结果。",
                usedNetwork: false
            )
        }
    }

    private static func featureDigest(for image: UIImage, similarity: Double) -> String {
        var hasher = SHA256()
        if let data = image.jpegData(compressionQuality: 0.4) {
            hasher.update(data: data)
        }
        var sim = similarity
        withUnsafeBytes(of: &sim) { hasher.update(bufferPointer: $0) }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
