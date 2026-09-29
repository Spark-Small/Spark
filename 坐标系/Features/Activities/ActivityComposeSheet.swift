//
//  ActivityComposeSheet.swift
//  坐标系
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

struct ActivityComposeSheet: View {
    var editingActivity: Activity? = nil
    var onPublish: (
        _ title: String,
        _ category: ActivityCategory,
        _ location: String,
        _ date: Date,
        _ capacity: Int,
        _ fee: String,
        _ summary: String,
        _ tags: [String],
        _ localCoverName: String?,
        _ latitude: Double?,
        _ longitude: Double?
    ) -> Void
    var onUpdate: ((
        _ id: Activity.ID,
        _ title: String,
        _ category: ActivityCategory,
        _ location: String,
        _ date: Date,
        _ capacity: Int,
        _ fee: String,
        _ summary: String,
        _ tags: [String],
        _ localCoverName: String?,
        _ latitude: Double?,
        _ longitude: Double?
    ) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app
    @State private var title = ""
    @State private var category: ActivityCategory = .outdoorSports
    @State private var location = ""
    @State private var date = Date().addingTimeInterval(3600 * 6)
    @State private var capacity = 8
    @State private var fee = "免费"
    @State private var summary = ""
    @State private var tagText = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var coverPreview: UIImage?
    @State private var localCoverName: String?
    /// 进入编辑时的封面；取消时用于回收本会话新写入的文件
    @State private var baselineCoverName: String?
    @State private var didCommitSave = false
    @State private var isPreparingCover = false
    @State private var didPrefill = false
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var showMapPicker = false
    @State private var moderationAlert: String?

    private var isEditing: Bool { editingActivity != nil }

    private var publishCategories: [ActivityCategory] {
        ActivityCategory.allCases.filter { !$0.isBrowseAggregate }
    }

    private var canPublish: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isPreparingCover
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let coverPreview {
                        Image(uiImage: coverPreview)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: PlatformMetrics.composeCoverHeight)
                            .clipShape(PlatformMetrics.mediaShape)
                    }

                    let coverActionTitle = localCoverName == nil ? "添加封面图" : "更换封面"
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(coverActionTitle, systemImage: "photo.on.rectangle.angled")
                            .frame(maxWidth: .infinity, minHeight: PlatformMetrics.galleryEditorThumb)
                    }
                    .onChange(of: pickerItem) { _, item in
                        Task { await loadCover(item) }
                    }
                    if isPreparingCover {
                        ProgressView("正在处理封面…")
                    }
                } header: {
                    Text("封面")
                }

                Section("基本信息") {
                    TextField("活动标题", text: $title)
                    Picker("类型", selection: $category) {
                        ForEach(publishCategories) { item in
                            Label(item.title, systemImage: item.systemImage)
                                .platformContentSymbolStyle()
                                .tag(item)
                        }
                    }
                    TextField("地点", text: $location)
                    Button {
                        showMapPicker = true
                    } label: {
                        Label(
                            latitude == nil ? "地图选点" : "已选坐标，点击重选",
                            systemImage: "map"
                        )
                        .platformContentSymbolStyle()
                    }
                    DatePicker("开始时间", selection: $date, in: Date()...)
                }

                Section("名额与费用") {
                    Stepper("人数 \(capacity)", value: $capacity, in: 2...40)
                    TextField("费用说明", text: $fee)
                }

                Section("介绍") {
                    TextField("一句话说明活动亮点…", text: $summary, axis: .vertical)
                        .lineLimit(3...8)
                    TextField("标签（空格分隔）", text: $tagText)
                }
            }
            .navigationTitle(isEditing ? "编辑活动" : "发起活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        discardUncommittedCoverIfNeeded()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "保存" : "发布") {
                        submit()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canPublish)
                }
            }
            .onAppear(perform: prefillIfNeeded)
            .onDisappear {
                if !didCommitSave {
                    discardUncommittedCoverIfNeeded()
                }
            }
            .sheet(isPresented: $showMapPicker) {
                ActivityMapPickerSheet(
                    locationText: $location,
                    latitude: $latitude,
                    longitude: $longitude
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .platformSheet(.form)
        .platformFeedbackAlert($moderationAlert)
    }

    private var parsedTags: [String] {
        tagText
            .split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "，" })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func prefillIfNeeded() {
        guard !didPrefill, let activity = editingActivity else { return }
        didPrefill = true
        title = activity.title
        category = activity.category.isBrowseAggregate ? .outdoorSports : activity.category
        location = activity.location
        date = max(activity.date, Date())
        capacity = max(activity.capacity, 2)
        fee = activity.fee
        summary = activity.summary
        tagText = activity.tags.joined(separator: " ")
        localCoverName = activity.localCoverName
        baselineCoverName = activity.localCoverName
        latitude = activity.latitude
        longitude = activity.longitude
        if let name = activity.localCoverName,
           let url = LocalMediaLibrary.fileURL(named: name),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            coverPreview = image
        }
    }

    private func discardUncommittedCoverIfNeeded() {
        LocalMediaLibrary.discardUncommitted(
            current: localCoverName.map { [$0] } ?? [],
            baseline: baselineCoverName.map { [$0] } ?? []
        )
    }

    private func submit() {
        let combined = [title, summary, tagText, location].joined(separator: "\n")
        if case .block(let reason) = ContentModeration.scanText(combined) {
            moderationAlert = reason
            return
        }
        // 编辑时替换封面：提交后再删旧文件
        if isEditing,
           let baseline = baselineCoverName,
           baseline != localCoverName {
            LocalMediaLibrary.delete(named: baseline)
        }
        didCommitSave = true
        if let activity = editingActivity, let onUpdate {
            onUpdate(
                activity.id, title, category, location, date, capacity, fee, summary,
                parsedTags, localCoverName, latitude, longitude
            )
        } else {
            onPublish(
                title, category, location, date, capacity, fee, summary,
                parsedTags, localCoverName, latitude, longitude
            )
        }
        dismiss()
    }

    @MainActor
    private func loadCover(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isPreparingCover = true
        defer { isPreparingCover = false }

        // 本会话内换图：先丢掉上一张未提交新图，保留基线封面文件
        if let old = localCoverName, old != baselineCoverName {
            LocalMediaLibrary.delete(named: old)
            localCoverName = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }

        let decision = await MediaModerationService.moderateImage(
            image,
            context: .activityCover,
            actorKey: app.user.name
        )
        if case .block(let reason) = decision {
            moderationAlert = reason
            return
        }

        guard let name = LocalMediaLibrary.saveJPEG(data) else { return }

        coverPreview = image
        localCoverName = name
    }
}
