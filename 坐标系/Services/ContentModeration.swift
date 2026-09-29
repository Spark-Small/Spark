//
//  ContentModeration.swift
//  坐标系
//
//  文本内容安全：本地词表扫描；青少年模式更严。
//  远程文本审核可经 FeatureFlags 扩展；当前默认仅本地。
//

import Foundation

enum ContentModeration {
    enum Decision: Equatable, Sendable {
        case allow
        case block(reason: String)
    }

    /// 通用敏感词（UGC 主路径）。
    static let sensitiveWords = [
        "赌博", "色情", "毒品", "诈骗", "加微信刷单",
        "代孕", "卖淫", "嫖娼", "冰毒", "大麻",
        "博彩", "网赌", "代开发票", "洗钱",
    ]

    /// 青少年模式额外拦截。
    static let youthExtraWords = [
        "约炮", "裸聊", "烟酒", "香烟", "白酒", "啤酒促销",
    ]

    /// 统一入口：发帖 / 聊天 / 资料 / 活动文案发送前调用。
    static func scanText(
        _ text: String,
        youthMode: Bool = YouthModePreference.isEnabled
    ) -> Decision {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .allow }

        var lexicon = sensitiveWords
        if youthMode {
            lexicon.append(contentsOf: youthExtraWords)
        }

        for word in lexicon where trimmed.localizedCaseInsensitiveContains(word) {
            return .block(reason: blockReason(for: word, youthMode: youthMode))
        }
        return .allow
    }

    /// 兼容旧调用：命中时返回词本身。
    static func containsSensitive(_ text: String) -> String? {
        switch scanText(text) {
        case .allow:
            return nil
        case .block(let reason):
            // 尽量抽出「」内词；否则整段 reason
            if let start = reason.firstIndex(of: "「"),
               let end = reason.firstIndex(of: "」"),
               start < end {
                return String(reason[reason.index(after: start)..<end])
            }
            return reason
        }
    }

    private static func blockReason(for word: String, youthMode: Bool) -> String {
        if youthMode {
            return "青少年模式下无法发送含「\(word)」的内容。如有误判可通过设置中的举报与申诉反馈。"
        }
        return "内容含敏感词「\(word)」，请修改后再发送。如有误判可通过设置中的举报与申诉反馈。"
    }
}
