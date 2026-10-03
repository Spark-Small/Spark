//
//  IdentityAccessGate.swift
//  坐标系
//
//  身份门禁：登录用户须完成认证照 + 摄像头人脸核验后，方可报名 / 预约 / 社交。
//

import CoordinateFeatureFlags
import CoordinateModels
import SwiftUI

/// 门禁打断语境：决定「为什么 / 下一步」文案，不改变判定规则。
enum IdentityGateSource: Equatable {
    case activityJoin
    case buddyBooking
    case messaging
    case generic
}

enum IdentityAccessGate {
    /// 缺认证照：通用兜底
    static let needPhotosReason = "预约、邀约与发消息前，需要先完成形象认证。"
    static let photosMissingNextStep = "下一步：在下方添加 1–2 张本人正脸认证照并保存；保存后继续做人脸核验。"

    /// 缺核验：通用兜底
    static let needCaptureReason = "认证照已就绪，还差一步摄像头核验（与认证照比对，影像优先本机处理）。"
    static let captureMissingNextStep = "下一步：点「开始核验」，正对镜头完成比对；通过后即可继续刚才的操作。"

    static func needPhotosReason(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "参加活动前，需要先完成形象认证。"
        case .buddyBooking:
            "预约或邀约前，需要先完成形象认证。"
        case .messaging:
            "发消息前，需要先完成形象认证。"
        case .generic:
            needPhotosReason
        }
    }

    static func photosMissingNextStep(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "下一步：添加 1–2 张本人正脸认证照并保存；保存后做人脸核验，通过即可参加。"
        case .buddyBooking, .messaging, .generic:
            photosMissingNextStep
        }
    }

    static func needCaptureReason(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "认证照已就绪，还差一步摄像头核验；通过后即可参加。"
        case .buddyBooking, .messaging, .generic:
            needCaptureReason
        }
    }

    static func captureMissingNextStep(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "下一步：点「开始核验」，正对镜头完成比对；通过后即可参加。"
        case .buddyBooking:
            "下一步：点「开始核验」，正对镜头完成比对；通过后即可继续预约或邀约。"
        case .messaging:
            "下一步：点「开始核验」，正对镜头完成比对；通过后即可发消息。"
        case .generic:
            captureMissingNextStep
        }
    }

    static func editProfileSectionHeader(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "继续参加前"
        case .buddyBooking:
            "继续预约 / 邀约前"
        case .messaging:
            "继续发消息前"
        case .generic:
            "继续操作前"
        }
    }

    static func captureSectionHeader(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "完成认证后即可参加"
        case .buddyBooking, .messaging, .generic:
            "还差一步"
        }
    }

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
        _ = auth
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
