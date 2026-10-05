//
//  ActivityDetailContentEditorSheet+FormSections.swift
//  坐标系
//
//  写实编辑：行程 / 装备 / 图库 Section（跨文件 extension，状态见主文件）。
//

import PhotosUI
import SwiftUI
import CoordinateModels

extension ActivityDetailContentEditorSheet {
    @ViewBuilder
    var timelineSection: some View {
        Section {
            if timelineRows.isEmpty {
                Text(timelineUsesTemplate ? "保存后使用类别默认行程" : "暂无行程节点，点击下方添加")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($timelineRows) { $row in
                    VStack(alignment: .leading) {
                        TextField("时间（如 09:30）", text: $row.time)
                            .platformFormTextInput(.singleLine)
                        TextField("环节（如 集合签到）", text: $row.title)
                            .platformFormTextInput(.singleLine)
                        TextField("说明", text: $row.detail, axis: .vertical)
                            .platformFormTextInput(.caption)
                    }
                }
                .onDelete(perform: deleteTimelineRows)
            }

            if timelineUsesTemplate {
                Button {
                    timelineRows = defaultTimelineRows()
                    timelineUsesTemplate = false
                } label: {
                    Label("基于类别默认编辑", systemImage: "doc.on.clipboard")
                }
            }

            Button {
                appendTimelineRow()
            } label: {
                Label("添加行程节点", systemImage: "plus.circle")
            }

            if !timelineRows.isEmpty || timelineUsesTemplate {
                Button("恢复类别默认行程", role: .destructive) {
                    restoreConfirmTarget = .timeline
                }
            }
        } header: {
            Text(ActivityDetailCopy.timelineEditorTitle)
        } footer: {
            Text(
                timelineUsesTemplate
                    ? "当前跟随类别默认模板，保存不写覆盖；可基于默认编辑或添加节点。"
                    : ActivityDetailCopy.timelineEditorHint
            )
        }
    }

    @ViewBuilder
    var gearSection: some View {
        Section {
            if gearRows.isEmpty {
                Text(gearUsesTemplate ? "保存后使用类别默认装备" : "暂无装备项，点击下方添加")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($gearRows) { $row in
                    VStack(alignment: .leading) {
                        TextField("名称（如 鞋）", text: $row.title)
                            .platformFormTextInput(.singleLine)
                        TextField("说明", text: $row.detail, axis: .vertical)
                            .platformFormTextInput(.caption)
                        Picker("图标", selection: $row.systemImage) {
                            ForEach(gearIconOptions, id: \.self) { icon in
                                Label(icon, systemImage: icon).tag(icon)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteGearRows)
            }

            if gearUsesTemplate {
                Button {
                    gearRows = defaultGearRows()
                    gearUsesTemplate = false
                } label: {
                    Label("基于类别默认编辑", systemImage: "doc.on.clipboard")
                }
            }

            Button {
                gearUsesTemplate = false
                gearRows.append(GearDraftRow(title: "装备", detail: "补充说明", systemImage: "backpack"))
            } label: {
                Label("添加装备项", systemImage: "plus.circle")
            }

            if !gearRows.isEmpty || gearUsesTemplate {
                Button("恢复类别默认装备", role: .destructive) {
                    restoreConfirmTarget = .gear
                }
            }
        } header: {
            Text(ActivityDetailCopy.gearEditorTitle)
        } footer: {
            Text(
                gearUsesTemplate
                    ? "当前跟随类别默认模板，保存不写覆盖。"
                    : ActivityDetailCopy.gearEditorHint
            )
        }
    }

    @ViewBuilder
    var gallerySection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(galleryNames.enumerated()), id: \.offset) { index, name in
                        if let ref = LocalMediaLibrary.mediaRef(named: name) {
                            ZStack(alignment: .topTrailing) {
                                CommunityRemotePhoto(ref: ref)
                                    .frame(
                                        width: PlatformMetrics.galleryEditorThumb,
                                        height: PlatformMetrics.galleryEditorThumb
                                    )
                                    .clipShape(PlatformMetrics.mediaShape)
                                Button {
                                    removeGalleryPhoto(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .platformSymbolStyle(.mediaBadge)
                                }
                                .offset(
                                    x: PlatformMetrics.galleryRemoveBadgeOffset,
                                    y: -PlatformMetrics.galleryRemoveBadgeOffset
                                )
                            }
                        }
                    }

                    if galleryNames.count < 5 {
                        PhotosPicker(
                            selection: $galleryPickerItems,
                            maxSelectionCount: 5 - galleryNames.count,
                            matching: LocalMediaLibrary.photosAndVideos
                        ) {
                            ActivityGalleryAddPlaceholder()
                        }
                        .onChange(of: galleryPickerItems) { _, items in
                            Task { await loadGalleryPhotos(items) }
                        }
                    }
                }
            }
        } header: {
            Text(ActivityDetailCopy.galleryEditorTitle)
        } footer: {
            Text(ActivityDetailCopy.galleryEditorHint)
        }
    }

    func defaultGearRows() -> [GearDraftRow] {
        ActivityDetailBlueprint.templateBlueprint(for: activity).gear.map {
            GearDraftRow(title: $0.title, detail: $0.detail, systemImage: $0.systemImage)
        }
    }

    func defaultTimelineRows() -> [TimelineDraftRow] {
        ActivityDetailBlueprint.templateBlueprint(for: activity).timeline.map {
            TimelineDraftRow(time: $0.time, title: $0.title, detail: $0.detail)
        }
    }

    func appendTimelineRow() {
        timelineUsesTemplate = false
        timelineRows.append(TimelineDraftRow(time: "10:00", title: "新环节", detail: "补充说明"))
    }

    func deleteTimelineRows(at offsets: IndexSet) {
        timelineUsesTemplate = false
        timelineRows.remove(atOffsets: offsets)
    }

    func deleteGearRows(at offsets: IndexSet) {
        gearUsesTemplate = false
        gearRows.remove(atOffsets: offsets)
    }

    func removeGalleryPhoto(at index: Int) {
        guard galleryNames.indices.contains(index) else { return }
        galleryNames.remove(at: index)
    }

    @MainActor
    func loadGalleryPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard galleryNames.count < 5,
                  let name = await LocalMediaLibrary.savePickerItem(item)
            else { continue }
            galleryNames.append(name)
        }
        galleryPickerItems = []
    }
}

/// PhotosPicker 标签独立成 View，避免 label 闭包与材质 helper 的 actor 隔离冲突。
struct ActivityGalleryAddPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title3.weight(.bold))
            Text("添加")
                .font(.caption)
        }
        .frame(width: PlatformMetrics.galleryEditorThumb, height: PlatformMetrics.galleryEditorThumb)
        .platformThinMaterialBackground(in: PlatformMetrics.mediaShape)
    }
}
