//
//  MessagesCopy+AttachSocial.swift
//  坐标系
//
//  附件菜单 / 通话 / 转账 / 举报文案。
//

import CoordinateModels
import Foundation

extension MessagesCopy {
    // MARK: - Attach / call / transfer / report

    static let attach = "更多"
    static let attachCamera = "相机"
    static let attachPhoto = "照片"
    static let attachVoice = "语音"
    static let attachLocation = "位置"
    static let attachActivity = "活动卡片"
    static let voiceCall = "语音通话"
    static let callConnecting = "连接中"
    static let callRinging = "等待接听"
    static let callMuted = "静音"
    static let callSpeaker = "扬声器"
    static let callCamera = "摄像头"
    static let callEnd = "挂断"
    static let callBackToChat = "返回聊天"
    static let callLocalModeHint = "本地开发态模拟通话，不会接通真实音视频流。"

    static let reportUser = "举报"
    static let reportTitle = "举报"
    static let reportReasons = ["骚扰辱骂", "欺诈广告", "色情低俗", "其他"]
    static let reportFooter = "我们会尽快核查。恶意举报可能影响账号权限。"

    static let transferTitle = "转账"
    static let transferAccept = "确认收款"
    static let transferCancel = "取消转账"
    static let transferRefund = "退回转账"
    static let transferDemoBadge = "本地转账"
    static func transferExpiresIn(_ interval: TimeInterval) -> String {
        let total = max(Int(interval), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours) 小时 \(minutes) 分钟后过期" }
        if minutes > 0 { return "\(minutes) 分钟后过期" }
        return "即将过期"
    }
    static func transferExpiredNotice(amount: Double) -> String {
        "转账 ¥\(String(format: "%.2f", amount)) 已过期"
    }
    static let currentLocation = "当前位置"
    static let mapLocationFallback = "地图位置"
    static func transferStatusLabel(_ status: TransferStatus) -> String { status.rawValue }
}
