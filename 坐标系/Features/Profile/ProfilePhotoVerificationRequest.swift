//
//  ProfilePhotoVerificationRequest.swift
//  坐标系
//
//  私聊内「请对方防欺诈认证」：本机发送文案请求，不伪造服务端已确认。
//

import Foundation

enum ProfilePhotoVerificationRequest {
    enum RequestGate: Equatable {
        case allowed
        case needSelfVerified
        case peerAlreadyVerified
    }

    static let menuTitle = "请对方防欺诈认证"
    static let needSelfVerifiedTitle = "请先完成自己的防欺诈认证"
    static let needSelfVerifiedMessage =
        "需要你先通过摄像头防欺诈认证，才能向对方发出认证请求。"
    static let peerAlreadyVerifiedTitle = "对方已认证"
    static let peerAlreadyVerifiedMessage = "对方资料已显示防欺诈认证标记。"
    static let sentFeedback = "已发送认证请求"

    /// 发出去的聊天文案（礼貌请求，非系统假状态）。
    static let chatMessage =
        "方便的话，可以去「我的 → 个人资料」完成防欺诈认证吗？我想确认一下真人～"

    static func canRequest(
        selfVerified: Bool,
        peerVerified: Bool
    ) -> RequestGate {
        if !selfVerified { return .needSelfVerified }
        if peerVerified { return .peerAlreadyVerified }
        return .allowed
    }
}
