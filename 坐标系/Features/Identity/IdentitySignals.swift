//
//  IdentitySignals.swift
//  坐标系
//
//  身份只读快照：Trust 徽章 / 公开卡统一消费，禁止业务手拼字段。
//

import CoordinateModels
import Foundation

struct IdentitySignals: Equatable, Sendable {
    var hasVerificationPhotosReady: Bool
    var photoVerified: Bool
    var realNameVerified: Bool
    var documentKind: RealNameDocumentKind?

    var identityVerified: Bool { realNameVerified }
}

enum IdentitySignalsBuilder {
    @MainActor
    static func snapshot(
        user: AppUser,
        photoVerification: PhotoVerificationStore
    ) -> IdentitySignals {
        IdentitySignals(
            hasVerificationPhotosReady: user.hasVerificationPhotosReady,
            photoVerified: photoVerification.isVerified(for: user),
            realNameVerified: user.isRealNameVerified,
            documentKind: user.realNameDocumentKind
        )
    }
}
