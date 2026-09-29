//
//  CommunityComposeSheet.swift
//  坐标系
//

import PhotosUI
import SwiftUI
import CoordinateModels

struct CommunityComposeSheet: View {
    @Environment(CommunityModel.self) private var model
    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var bodyText = ""
    @State private var tagText = ""
    @State private var relatedActivityID: UUID?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewImages: [UIImage] = []
    @State private var savedPhotoNames: [String] = []
    @State private var isPreparingPhotos = false
    @State private var blockedWord: String?
    @State private var moderationAlert: String?
    @State private var photoImportAlert: String?
    @State private var recapSourceActivityID: UUID?
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
                    let mediaPickerTitle = PlatformPhotosPickerCopy.mediaCountLabel(
                        count: previewImages.count,
                        emptyTitle: "添加照片或视频"
                    )
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: maxPhotos,
                        matching: LocalMediaLibrary.photosAndVideos,
                        photoLibrary: .shared()
                    ) {
                        Label(mediaPickerTitle, systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: pickerItems) { _, items in
                        Task { await loadPhotos(items) }
                    }

                    if !previewImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: PlatformMetrics.minContentGap) {
                                ForEach(Array(previewImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: PlatformMetrics.galleryEditorThumb, height: PlatformMetrics.galleryEditorThumb)
                                        .clipShape(RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous))
                                        .overlay {
                                            if savedPhotoNames.indices.contains(index),
                                               LocalMediaLibrary.isVideo(name: savedPhotoNames[index]) {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.title3)
                                                    .symbolRenderingMode(.hierarchical)
                                                    .foregroundStyle(.white)
                                            }
                                        }
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
                        ProgressView("正在处理媒体…")
                    }
                } header: {
                    Text("照片与视频")
                } footer: {
                    Text("最多 \(maxPhotos) 项，发布后保存在本机")
                }

                Section("标签") {
                    TextField("用空格分隔，如 夜骑 新手", text: $tagText)
                        .focused($focused, equals: .tags)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PlatformMetrics.minContentGap) {
                            ForEach(suggestedTags, id: \.self) { tag in
                                PlatformFilterChipButton(
                                    title: tag,
                                    systemImage: "number",
                                    isSelected: tagText
                                        .split(whereSeparator: \.isWhitespace)
                                        .map(String.init)
                                        .contains(tag)
                                ) {
                                    appendTag(tag)
                                }
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
                if let recapID = recapSourceActivityID {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(ActivityExperienceFeedbackCopy.skip) {
                            activities.skipActivityRecap(recapID)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布", action: publish)
                        .fontWeight(.semibold)
                        .disabled(!canPublish)
                }
            }
            .onAppear {
                applyInitialValues()
                recapSourceActivityID = model.pendingRelatedActivityID
            }
        }
        .platformSheet(.form)
        .platformFeedbackAlert($moderationAlert)
        .platformFeedbackAlert($photoImportAlert, title: "")
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
            if let activityID = matched?.id {
                activities.markActivityRecapPublished(activityID)
            }
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
            LocalMediaLibrary.delete(named: savedPhotoNames[index])
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
            LocalMediaLibrary.delete(named: name)
        }
        savedPhotoNames = []
        previewImages = []

        var importFailures = 0
        for item in items {
            guard let name = await LocalMediaLibrary.savePickerItem(item),
                  let url = LocalMediaLibrary.fileURL(named: name)
            else {
                importFailures += 1
                continue
            }
            let preview: UIImage?
            if LocalMediaLibrary.isVideo(url: url) {
                preview = await LocalMediaLibrary.posterImage(for: url)
            } else {
                preview = await PlatformLocalImageCache.loadAsync(atPath: url.path)
            }
            guard let preview else {
                LocalMediaLibrary.delete(named: name)
                importFailures += 1
                continue
            }
            if !LocalMediaLibrary.isVideo(url: url) {
                let decision = await MediaModerationService.moderateImage(
                    preview,
                    context: .community,
                    actorKey: app.user.name
                )
                if case .block(let reason) = decision {
                    LocalMediaLibrary.delete(named: name)
                    moderationAlert = reason
                    continue
                }
            }
            previewImages.append(preview)
            savedPhotoNames.append(name)
        }
        if importFailures > 0, previewImages.isEmpty {
            photoImportAlert = CommunityCopy.photoImportFailed
        } else if importFailures > 0 {
            photoImportAlert = "有 \(importFailures) 项未能导入，已保留可加载的媒体。"
        }
    }
}
