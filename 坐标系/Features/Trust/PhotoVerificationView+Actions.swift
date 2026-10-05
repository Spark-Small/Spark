//
//  PhotoVerificationView+Actions.swift
//  坐标系
//

import CoordinateModels
import SwiftUI
import UIKit

extension PhotoVerificationView {
    func loadImage(named: String) -> UIImage? {
        guard let url = LocalMediaLibrary.fileURL(named: named),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    func runVerification() async {
        guard let capture else { return }
        guard !store.isInCooldown else { return }
        let references = app.user.localVerificationImages()
        guard !references.isEmpty else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }
        remoteNote = nil

        let result = await PhotoVerificationEngine.verify(references: references, capture: capture)
        outcome = result
        guard result.passed else {
            store.recordFailure(userKey: app.user.name)
            return
        }

        let remote = await IdentityRemoteReverifyService.reverify(
            userKey: app.user.name,
            baselineFingerprint: app.user.verificationBaselineFingerprint,
            localSimilarity: result.similarity,
            capture: capture,
            youthMode: youthMode.isEnabled
        )
        if let reason = remote.reason {
            remoteNote = reason
        }
        guard remote.passed else {
            outcome = PhotoVerificationEngine.Outcome(
                passed: false,
                similarity: remote.remoteScore,
                reasons: [remote.reason ?? "二次复核未通过，请重试。"]
            )
            store.recordFailure(userKey: app.user.name)
            return
        }

        store.markVerified(
            userKey: app.user.name,
            similarity: max(result.similarity, remote.remoteScore),
            photos: app.user.verificationPhotos,
            remoteVerified: remote.usedNetwork
        )
        trust.record(
            .profileCompletionChanged,
            domain: .account,
            actorKey: app.user.name,
            note: "photo_verified"
        )
        if remote.usedNetwork {
            trust.record(
                .identityRemoteVerified,
                domain: .moderation,
                actorKey: app.user.name,
                note: "network"
            )
        }
        app.pendingIdentityVerification = false
    }

    func submitIdentityAppeal() {
        app.addModerationTicket(
            postID: app.user.id,
            title: "防欺诈认证申诉 · \(app.user.name)",
            reason: "用户认为防欺诈认证误判，申请人工复核。连续失败 \(store.consecutiveFailures) 次。",
            targetKind: .identityAppeal
        )
        appealFeedback = "已提交防欺诈认证申诉，可在设置 → 举报与申诉中查看进度。"
    }
}
