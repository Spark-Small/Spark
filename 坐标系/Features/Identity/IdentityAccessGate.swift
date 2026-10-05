//
//  IdentityAccessGate.swift
//  坐标系
//
//  身份门禁规则：登录用户须完成认证照 + 摄像头人脸核验后，方可报名 / 预约 / 社交。
//

import CoordinateFeatureFlags
import CoordinateModels
import Foundation

/// 门禁打断语境：决定「为什么 / 下一步」文案，不改变判定规则。
enum IdentityGateSource: Equatable {
    case activityJoin
    case buddyBooking
    case messaging
    case generic
}

enum IdentityAccessGate {
    typealias Requirement = IdentityCapability.Requirement

    /// 文案转发（兼容旧调用点）。
    static let needPhotosReason = IdentityAccessCopy.needPhotosReason
    static let photosMissingNextStep = IdentityAccessCopy.photosMissingNextStep
    static let needCaptureReason = IdentityAccessCopy.needCaptureReason
    static let captureMissingNextStep = IdentityAccessCopy.captureMissingNextStep

    static func needPhotosReason(for source: IdentityGateSource) -> String {
        IdentityAccessCopy.needPhotosReason(for: source)
    }

    static func photosMissingNextStep(for source: IdentityGateSource) -> String {
        IdentityAccessCopy.photosMissingNextStep(for: source)
    }

    static func needCaptureReason(for source: IdentityGateSource) -> String {
        IdentityAccessCopy.needCaptureReason(for: source)
    }

    static func captureMissingNextStep(for source: IdentityGateSource) -> String {
        IdentityAccessCopy.captureMissingNextStep(for: source)
    }

    static func editProfileSectionHeader(for source: IdentityGateSource) -> String {
        IdentityAccessCopy.editProfileSectionHeader(for: source)
    }

    static func captureSectionHeader(for source: IdentityGateSource) -> String {
        IdentityAccessCopy.captureSectionHeader(for: source)
    }

    @MainActor
    static func requirement(
        user: AppUser,
        auth: LocalAuthSession,
        photoVerification: PhotoVerificationStore
    ) -> Requirement {
        IdentityCapability.requirement(
            user: user,
            auth: auth,
            photoVerification: photoVerification
        )
    }
}
