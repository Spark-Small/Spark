//
//  CommunityComposeSheet.swift
//  坐标系
//

import PhotosUI
import SwiftUI

struct CommunityComposeSheet: View {
    @Environment(CommunityModel.self) private var model
    @Environment(ActivitiesModel.self) private var activities
    @Environment(\.dismiss) private var dismiss

    @State private var bodyText = ""
    @State private var tagText = ""
    @State private var relatedActivityID: UUID?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewImages: [UIImage] = []
    @State private var savedPhotoNames: [String] = []
    @State private var isPreparingPhotos = false
    @State private var blockedWord: String?
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case body, tags
    }

    private let suggestedTags = ["经验", "探店", "路线", "周末", "夜骑", "美食"]
    private let maxPhotos = 9

    private var linkableActivities: [Activity] {
        let prioritized = activities.inviteableActivities
        if !prioritized.isEmpty { return prioritized }
        return activities.activities.filter { !$0.isPast }.sorted { $0.date < $1.date }
    }

    private var canPublish: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isPreparingPhotos
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("写下路线、体验或避坑…", text: $bodyText, axis: .vertical)
                        .lineLimit(4...10)
                        .focused($focused, equals: .body)
                } header: {
                    Text("内容")
                } footer: {
                    Text("适合活动复盘、探店笔记和路线攻略")
                }

                Section {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: maxPhotos,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            previewImages.isEmpty ? "添加图片" : "已选 \(previewImages.count) 张，点击更换",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                    .onChange(of: pickerItems) { _, items in
                        Task { await loadPhotos(items) }
                    }

                    if !previewImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(previewImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 88, height: 88)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                removePhoto(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .platformSymbolStyle(
                                                        .badge(primary: .white, secondary: .black.opacity(0.55))
                                                    )
                                            }
                                        }
                                }
                            }
                        }
                    }

                    if isPreparingPhotos {
                        ProgressView("正在处理图片…")
                    }
                } header: {
                    Text("图片")
                } footer: {
                    Text("最多 \(maxPhotos) 张，发布后保存在本机")
                }

                Section("标签") {
                    TextField("用空格分隔，如 夜骑 新手", text: $tagText)
                        .focused($focused, equals: .tags)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(suggestedTags, id: \.self) { tag in
                                Button(tag) { appendTag(tag) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                        }
                    }
                }

                Section("关联活动（可选）") {
                    Picker("活动", selection: $relatedActivityID) {
                        Text("不关联").tag(UUID?.none)
                        ForEach(linkableActivities) { activity in
                            Text(activity.title).tag(Optional(activity.id))
                        }
                    }
                }
            }
            .navigationTitle("发分享")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布", action: publish)
                        .fontWeight(.semibold)
                        .disabled(!canPublish)
                }
            }
            .onAppear(perform: applyInitialValues)
        }
        .platformSheet(.form)
        .alert("内容需要修改", isPresented: Binding(
            get: { blockedWord != nil },
            set: { if !$0 { blockedWord = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("检测到敏感词「\(blockedWord ?? "")」，请修改后再发布。")
        }
    }

    private var parsedTags: [String] {
        tagText
            .split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "，" })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func applyInitialValues() {
        if let initialBody = model.pendingComposeBody, bodyText.isEmpty {
            bodyText = initialBody
        }
        if relatedActivityID == nil {
            if let initialID = model.pendingRelatedActivityID {
                relatedActivityID = initialID
            } else if let initialTitle = model.pendingRelatedActivityTitle {
                relatedActivityID = linkableActivities.first { $0.title == initialTitle }?.id
            }
        }
        focused = .body
    }

    private func publish() {
        let matched = linkableActivities.first { $0.id == relatedActivityID }
        switch model.publish(
            body: bodyText,
            tags: parsedTags,
            relatedActivityTitle: matched?.title,
            relatedActivityID: matched?.id,
            localPhotoNames: savedPhotoNames
        ) {
        case .published:
            dismiss()
        case .blocked(let word):
            blockedWord = word
        case .invalid:
            break
        }
    }

    private func appendTag(_ tag: String) {
        if tagText.isEmpty {
            tagText = tag
        } else if !parsedTags.contains(tag) {
            tagText += " \(tag)"
        }
    }

    private func removePhoto(at index: Int) {
        guard previewImages.indices.contains(index) else { return }
        previewImages.remove(at: index)
        if savedPhotoNames.indices.contains(index) {
            CommunityPhotoStore.delete(named: savedPhotoNames[index])
            savedPhotoNames.remove(at: index)
        }
        if pickerItems.indices.contains(index) {
            pickerItems.remove(at: index)
        }
    }

    @MainActor
    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        isPreparingPhotos = true
        defer { isPreparingPhotos = false }

        for name in savedPhotoNames {
            CommunityPhotoStore.delete(named: name)
        }
        savedPhotoNames = []
        previewImages = []

        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let name = CommunityPhotoStore.saveJPEG(data)
            else { continue }
            previewImages.append(image)
            savedPhotoNames.append(name)
        }
    }
}
