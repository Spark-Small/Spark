//
//  BuddyVoiceIntroCopy.swift
//  坐标系
//
//  语音介绍录制文案。
//

import Foundation

nonisolated enum BuddyVoiceIntroCopy {
    static let publicSectionTitle = "语音介绍"
    static let publicFallbackCaption = "听听 TA 的声音"
    static let editRowTitle = "语音介绍"
    static let editEmptyValue = "未添加"
    static let editAddTitle = "添加语音介绍"
    static let recordSheetTitle = "语音介绍"
    static let recordHint = "按住下方按钮录制，松手完成。录好后会展示在你的搭子资料页。"
    static let captionLabel = "一句话说明（可选）"
    static let captionPlaceholder = "例如：周末常约羽毛球，欢迎打招呼"
    static let holdToRecord = "按住录音"
    static let releaseToFinish = "松手完成"
    static let save = "保存"
    static let cancel = "取消"
    static let removeVoice = "删除语音"
    static let playAccessibility = "播放语音介绍"
    static let pauseAccessibility = "暂停播放"
    static func recordDurationA11y(_ durationLabel: String) -> String { "录音时长 \(durationLabel)" }
}
