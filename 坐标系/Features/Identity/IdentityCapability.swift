//
//  IdentityCapability.swift
//  坐标系
//
//  身份能力门面：业务只问「能否参与」，不直接啃认证照 / 实名字段。
//

import CoordinateFeatureFlags
import CoordinateModels
import Foundation

enum IdentityCapability {
    enum Requirement: Equatable {
        case satisfied
        case photosMissing
        case verificationMissing
    }

    /// 门禁判定（不含 pending Sheet 副作用）。
    @MainActor
    static func requirement(
        user: AppUser,
        auth: LocalAuthSession,
        photoVerification: PhotoVerificationStore
    ) -> Requirement {
        guard FeatureFlags.requireIdentityVerification else { return .satisfied }
        _ = auth
        guard user.hasVerificationPhotosReady else { return .photosMissing }
        guard photoVerification.isVerified(for: user) else { return .verificationMissing }
        return .satisfied
    }

    /// 是否已满足参与能力（报名 / 预约 / 发消息）。
    @MainActor
    static func canParticipate(
        user: AppUser,
        auth: LocalAuthSession,
        photoVerification: PhotoVerificationStore
    ) -> Bool {
        requirement(user: user, auth: auth, photoVerification: photoVerification) == .satisfied
    }

    @MainActor
    static func signals(
        user: AppUser,
        photoVerification: PhotoVerificationStore
    ) -> IdentitySignals {
        IdentitySignalsBuilder.snapshot(user: user, photoVerification: photoVerification)
    }
}
