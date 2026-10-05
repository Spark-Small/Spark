//
//  IdentityAccessCopy.swift
//  坐标系
//
//  身份门禁文案（按打断语境分流；不改变判定规则）。
//

import Foundation

enum IdentityAccessCopy {
    static let needPhotosReason = "预约、邀约与发消息前，需要先完成防欺诈认证。"
    static let photosMissingNextStep = "下一步：进入防欺诈认证，添加 1–2 张本人正脸认证照；添加后即可继续做人脸核验。"
    static let needCaptureReason = "认证照已就绪，还差一步摄像头核验（与认证照比对，影像优先本机处理）。"
    static let captureMissingNextStep = "下一步：点「开始核验」，正对镜头完成比对；通过后即可继续刚才的操作。"

    static func needPhotosReason(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "参加活动前，需要先完成防欺诈认证。"
        case .buddyBooking:
            "预约或邀约前，需要先完成防欺诈认证。"
        case .messaging:
            "发消息前，需要先完成防欺诈认证。"
        case .generic:
            needPhotosReason
        }
    }

    static func photosMissingNextStep(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin:
            "下一步：进入防欺诈认证，添加 1–2 张本人正脸认证照；添加后即可做人脸核验，通过即可参加。"
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
        case .activityJoin: "继续参加前"
        case .buddyBooking: "继续预约 / 邀约前"
        case .messaging: "继续发消息前"
        case .generic: "继续操作前"
        }
    }

    static func captureSectionHeader(for source: IdentityGateSource) -> String {
        switch source {
        case .activityJoin: "完成认证后即可参加"
        case .buddyBooking, .messaging, .generic: "还差一步"
        }
    }
}
