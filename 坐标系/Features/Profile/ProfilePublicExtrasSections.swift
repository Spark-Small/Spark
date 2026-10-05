//
//  ProfilePublicExtrasSections.swift
//  坐标系
//
//  好友 / 作者 / 详情共用：基本资料 chips、意图、Prompt。
//

import CoordinateModels
import SwiftUI

enum ProfilePublicExtrasCopy {
    static let basicsHeader = "我的基础"
    static let intentHeader = "我想怎么玩"
    static let promptsHeader = "关于我"
    static let gender = "性别"
    static let age = "年龄"
    static let height = "身高"
    static let weight = "体重"
    static let availability = "档期"
    static let occupation = "身份"
    static let meetRadius = "出行"
    static let mbti = "MBTI"
    static let zodiac = "星座"
    static func ageValue(_ age: Int) -> String { "\(age) 岁" }
    static func heightValue(_ cm: Int) -> String { "\(cm) cm" }
    static func weightValue(_ kg: Int) -> String { "\(kg) kg" }
}

/// Form/List 分区：人口学 + 身份 + 半径 + 意图摘要。
struct ProfilePublicBasicsSection: View {
    let fields: ProfilePublicFields

    var body: some View {
        if fields.hasBasics {
            Section {
                if let gender = fields.gender {
                    LabeledContent(ProfilePublicExtrasCopy.gender, value: gender.rawValue)
                }
                if let age = fields.age, age > 0 {
                    LabeledContent(ProfilePublicExtrasCopy.age, value: ProfilePublicExtrasCopy.ageValue(age))
                }
                if let height = fields.heightCM, height > 0 {
                    LabeledContent(
                        ProfilePublicExtrasCopy.height,
                        value: ProfilePublicExtrasCopy.heightValue(height)
                    )
                }
                if let weight = fields.weightKG, weight > 0 {
                    LabeledContent(
                        ProfilePublicExtrasCopy.weight,
                        value: ProfilePublicExtrasCopy.weightValue(weight)
                    )
                }
                if let occupation = fields.occupation {
                    LabeledContent(ProfilePublicExtrasCopy.occupation, value: occupation.rawValue)
                }
                if let radius = fields.meetRadius {
                    LabeledContent(ProfilePublicExtrasCopy.meetRadius, value: radius.rawValue)
                }
                if let mbti = fields.mbti {
                    LabeledContent(ProfilePublicExtrasCopy.mbti, value: mbti.rawValue)
                }
                if let zodiac = fields.zodiac {
                    LabeledContent(ProfilePublicExtrasCopy.zodiac, value: zodiac.rawValue)
                }
                if !fields.availability.isEmpty {
                    LabeledContent(ProfilePublicExtrasCopy.availability, value: fields.availability)
                }
                if !fields.intentDisplayLine.isEmpty {
                    LabeledContent(ProfilePublicExtrasCopy.intentHeader, value: fields.intentDisplayLine)
                }
            } header: {
                Text(ProfilePublicExtrasCopy.basicsHeader)
            }
        }
    }
}

/// Prompt 卡片列表（只读）。
struct ProfilePublicPromptsSection: View {
    let prompts: [ProfilePrompt]

    var body: some View {
        if !prompts.isEmpty {
            Section {
                ForEach(prompts) { prompt in
                    VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                        Text(ProfilePromptCatalog.title(for: prompt.promptKey))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(prompt.answer)
                            .font(.body)
                            .foregroundStyle(.primary)
                        if let mediaName = prompt.mediaName, !mediaName.isEmpty {
                            ProfileGalleryThumb(localName: mediaName)
                                .frame(maxWidth: 160)
                                .frame(height: PlatformMetrics.galleryEditorThumb)
                        }
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text(ProfilePublicExtrasCopy.promptsHeader)
            }
        }
    }
}
