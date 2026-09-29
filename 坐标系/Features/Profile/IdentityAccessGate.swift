//
//  IdentityAccessGate.swift
//  坐标系
//
//  身份门禁：登录用户须完成认证照 + 摄像头人脸核验后，方可报名 / 预约 / 社交。
//

import CoordinateFeatureFlags
import CoordinateModels
import SwiftUI

enum IdentityAccessGate {
    static let needPhotosReason = "请先在个人资料上传 1–2 张认证照片，再进行摄像头人脸核验。"
    static let needCaptureReason = "使用报名、预约与消息前，请完成摄像头人脸核验（与认证照比对）。"

    enum Requirement: Equatable {
        case satisfied
        case photosMissing
        case verificationMissing
    }

    @MainActor
    static func requirement(
        user: AppUser,
        auth: LocalAuthSession,
        photoVerification: PhotoVerificationStore
    ) -> Requirement {
        guard FeatureFlags.requireIdentityVerification else { return .satisfied }
        guard !auth.isGuest else { return .satisfied }
        guard user.hasVerificationPhotosReady else { return .photosMissing }
        guard photoVerification.isVerified(for: user) else { return .verificationMissing }
        return .satisfied
    }

    /// 未满足则弹出对应 Sheet，返回 false。
    @MainActor
    @discardableResult
    static func allow(
        user: AppUser,
        auth: LocalAuthSession,
        photoVerification: PhotoVerificationStore,
        presentEditProfile: Binding<Bool>,
        presentVerification: Binding<Bool>
    ) -> Bool {
        switch requirement(user: user, auth: auth, photoVerification: photoVerification) {
        case .satisfied:
            return true
        case .photosMissing:
            presentEditProfile.wrappedValue = true
            return false
        case .verificationMissing:
            presentVerification.wrappedValue = true
            return false
        }
    }
}
