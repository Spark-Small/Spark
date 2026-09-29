//
//  CircleComposeSheet.swift
//  坐标系
//
//  创建俱乐部：名称由用户自定义，与单场活动无绑定。
//

import SwiftUI
import CoordinateModels

enum CircleComposeCopy {
    static let title = "创建俱乐部"
    static let nameSection = "俱乐部名称"
    static let namePlaceholder = "起一个好记的名字"
    static let nameFooter = "2–20 字，同城内不可与已有俱乐部重名。"
    static let topicSection = "主题"
    static let citySection = "所在城市"
    static let summarySection = "简介"
    static let summaryPlaceholder = "介绍一下你们的玩法、节奏和适合谁加入"
    static let summaryFooter = "至少 8 个字，会展示在俱乐部资料页。"
    static let tagsSection = "标签"
    static let tagsPlaceholder = "夜骑、入门友好（用逗号分隔）"
    static let publish = "创建并加入"
}

enum ClubTopicOption: String, CaseIterable, Identifiable {
    case cycling = "骑行"
    case outdoor = "户外"
    case sports = "运动"
    case food = "美食"
    case play = "玩乐"
    case entertainment = "娱乐"
    case coffee = "咖啡"
    case hiking = "徒步"
    case photo = "摄影"
    case badminton = "羽毛球"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .cycling: "bicycle"
        case .outdoor: "figure.hiking"
        case .sports: "figure.run"
        case .food: "fork.knife"
        case .play: "bag"
        case .entertainment: "gamecontroller"
        case .coffee: "cup.and.saucer"
        case .hiking: "figure.hiking"
        case .photo: "camera"
        case .badminton: "figure.badminton"
        }
    }
}

struct CircleComposeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BuddiesModel.self) private var buddies

    var onCreate: (InterestCircle) -> Void

    @State private var name = ""
    @State private var topic: ClubTopicOption = .cycling
    @State private var cityID = BuddyCityCatalog.default.id
    @State private var summary = ""
    @State private var tagText = ""
    @State private var nameError: String?

    private var selectedCity: BuddyCityChoice {
        BuddyCityCatalog.city(id: cityID) ?? BuddyCityCatalog.default
    }

    private var parsedTags: [String] {
        tagText
            .split(separator: "，")
            .flatMap { $0.split(separator: ",") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var canPublish: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        return buddies.validateClubName(trimmedName) == nil
            && trimmedSummary.count >= 8
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(CircleComposeCopy.namePlaceholder, text: $name)
                        .textInputAutocapitalization(.never)
                        .onChange(of: name) { _, _ in
                            nameError = buddies.validateClubName(name)
                        }
                    if let nameError {
                        Text(nameError)
                            .font(.caption)
                            .foregroundStyle(PlatformStatus.warning)
                    }
                } header: {
                    Text(CircleComposeCopy.nameSection)
                } footer: {
                    Text(CircleComposeCopy.nameFooter)
                }

                Section(CircleComposeCopy.topicSection) {
                    Picker("主题", selection: $topic) {
                        ForEach(ClubTopicOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .platformContentSymbolStyle()
                                .tag(option)
                        }
                    }
                }

                Section(CircleComposeCopy.citySection) {
                    Picker("城市", selection: $cityID) {
                        ForEach(BuddyCityCatalog.all) { city in
                            Text(city.menuTitle).tag(city.id)
                        }
                    }
                }

                Section {
                    TextField(CircleComposeCopy.summaryPlaceholder, text: $summary, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(CircleComposeCopy.summarySection)
                } footer: {
                    Text(CircleComposeCopy.summaryFooter)
                }

                Section(CircleComposeCopy.tagsSection) {
                    TextField(CircleComposeCopy.tagsPlaceholder, text: $tagText)
                }
            }
            .navigationTitle(CircleComposeCopy.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CircleComposeCopy.publish) {
                        publish()
                    }
                    .disabled(!canPublish)
                }
            }
        }
    }

    private func publish() {
        guard let circle = buddies.createClub(
            name: name,
            topic: topic.rawValue,
            city: selectedCity.menuTitle,
            summary: summary,
            tags: parsedTags,
            systemImage: topic.systemImage
        ) else {
            nameError = buddies.validateClubName(name)
            return
        }
        onCreate(circle)
        dismiss()
    }
}
