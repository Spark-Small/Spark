//
//  ProfilePrompt.swift
//  CoordinateModels
//
//  资料 Prompt：开聊钩子（对齐 Bumble prompts，语义偏出门 / 搭子）。
//

import Foundation

public struct ProfilePrompt: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var promptKey: String
    public var answer: String
    /// 可选：绑定生活墙本机文件名
    public var mediaName: String?

    public init(
        id: UUID = UUID(),
        promptKey: String,
        answer: String,
        mediaName: String? = nil
    ) {
        self.id = id
        self.promptKey = promptKey
        self.answer = answer
        self.mediaName = mediaName
    }
}

public enum ProfilePromptLimits {
    public static let maxCount = 3
    public static let answerMax = 80

    public static func clamped(_ prompts: [ProfilePrompt]) -> [ProfilePrompt] {
        Array(prompts.prefix(maxCount)).map { prompt in
            var copy = prompt
            copy.answer = String(
                copy.answer.trimmingCharacters(in: .whitespacesAndNewlines).prefix(answerMax)
            )
            return copy
        }
        .filter { !$0.answer.isEmpty && !$0.promptKey.isEmpty }
    }
}

public enum ProfilePromptCatalog {
    public static let all: [(key: String, title: String)] = [
        ("weekPlan", "本周想去的一场"),
        ("buddyCare", "找搭子时我最在意"),
        ("hostStyle", "我带人出门的风格"),
        ("dealBreaker", "绝不踩的坑"),
        ("foodDescribe", "用一道菜形容我"),
        ("energy", "白天人 / 夜猫子"),
        ("firstMeet", "第一次见面我想…"),
        ("rainPlan", "下雨天我更想"),
        ("groupSize", "我舒服的局规模"),
        ("chatHook", "私信可以先聊")
    ]

    public static func title(for key: String) -> String {
        all.first(where: { $0.key == key })?.title ?? key
    }

    public static var keys: [String] { all.map(\.key) }
}
