//
//  ActivityJoinConfirmSheet.swift
//  坐标系
//
//  参加前确认、支付前确认、发起人内容编辑（含行程时间轴）。
//

import PhotosUI
import SwiftUI
import UIKit

struct ActivityJoinConfirmSheet: View {
    let activity: Activity
    var onConfirm: (_ note: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("活动") {
                        Text(activity.title)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("时间") {
                        Text(Formatters.activityEventTime(from: activity.date))
                    }
                    LabeledContent("地点") {
                        Text(activity.location)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("费用") {
                        Text(activity.fee)
                            .fontWeight(.semibold)
                    }
                    LabeledContent("名额") {
                        Text("\(activity.joined)/\(activity.capacity)")
                    }
                } footer: {
                    Text(activity.requiresInAppPayment
                        ? ActivityDetailCopy.joinConfirmPaidHint
                        : ActivityDetailCopy.joinConfirmMessage)
                }

                Section("留言") {
                    TextField(ActivityDetailCopy.joinConfirmNotePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle(ActivityDetailCopy.joinConfirmTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(nextCTA) {
                        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        onConfirm(trimmed.isEmpty ? nil : trimmed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .platformSheet(.confirm)
    }

    private var nextCTA: String {
        if !activity.requiresInAppPayment || ActivityPaymentStore.hasPaid(for: activity.id) {
            return ActivityDetailCopy.joinConfirmTitle
        }
        return ActivityDetailCopy.joinConfirmPayCTA
    }
}

struct TimelineDraftRow: Identifiable, Hashable {
    let id: UUID
    var time: String
    var title: String
    var detail: String

    init(id: UUID = UUID(), time: String, title: String, detail: String) {
        self.id = id
        self.time = time
        self.title = title
        self.detail = detail
    }
}

struct GearDraftRow: Identifiable, Hashable {
    let id: UUID
    var title: String
    var detail: String
    var systemImage: String

    init(id: UUID = UUID(), title: String, detail: String, systemImage: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }
}

private let gearIconOptions = [
    "backpack", "shoeprints.fill", "tshirt", "drop", "sun.max", "bag",
    "book", "battery.100", "figure.walk", "cup.and.saucer", "paintbrush.pointed", "fork.knife"
]

/// 发起人写实编辑：覆盖详情模板中的行程 / 须知 / 补充说明
struct ActivityDetailContentEditorSheet: View {
    let activity: Activity
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hostNote = ""
    @State private var prepNotesText = ""
    @State private var registrationNotesText = ""
    @State private var feeIncludedText = ""
    @State private var feeExcludedText = ""
    @State private var refundNotesText = ""
    @State private var timelineRows: [TimelineDraftRow] = []
    @State private var gearRows: [GearDraftRow] = []
    @State private var galleryNames: [String] = []
    @State private var baselineGalleryNames: [String] = []
    @State private var galleryPickerItems: [PhotosPickerItem] = []
    @State private var didCommitSave = false
    /// 恢复类别默认：保存时 timeline / gear 写 nil，不固化模板副本
    @State private var timelineUsesTemplate = false
    @State private var gearUsesTemplate = false

    var body: some View {
        NavigationStack {
            Form {
                gallerySection
                timelineSection
                gearSection

                Section {
                    TextField("补充说明（展示在决策卡）", text: $hostNote, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("发起人补充")
                }

                Section("准备 / 风险提示（每行一条）") {
                    TextField("例如：请自备饮水", text: $prepNotesText, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section(ActivityDetailCopy.notesEditorSection) {
                    TextField("例如：开始前 6 小时可取消", text: $registrationNotesText, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("费用包含（每行一条）") {
                    TextField("例如：场地协调", text: $feeIncludedText, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("费用不含（每行一条）") {
                    TextField("例如：个人交通", text: $feeExcludedText, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("退改说明（每行一条）") {
                    TextField("例如：开始前 24 小时可取消", text: $refundNotesText, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle("完善活动说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        discardUncommittedGalleryIfNeeded()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        onSaved()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear(perform: prefill)
            .onDisappear {
                if !didCommitSave {
                    discardUncommittedGalleryIfNeeded()
                }
            }
        }
        .platformSheet(.form)
    }

    @ViewBuilder
    private var timelineSection: some View {
        Section {
            if timelineRows.isEmpty {
                Text(timelineUsesTemplate ? "保存后使用类别默认行程" : "暂无行程节点，点击下方添加")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($timelineRows) { $row in
                    VStack(alignment: .leading) {
                        TextField("时间（如 09:30）", text: $row.time)
                        TextField("环节（如 集合签到）", text: $row.title)
                        TextField("说明", text: $row.detail, axis: .vertical)
                            .lineLimit(2...4)
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
                    timelineRows = []
                    timelineUsesTemplate = true
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
    private var gearSection: some View {
        Section {
            if gearRows.isEmpty {
                Text(gearUsesTemplate ? "保存后使用类别默认装备" : "暂无装备项，点击下方添加")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($gearRows) { $row in
                    VStack(alignment: .leading) {
                        TextField("名称（如 鞋）", text: $row.title)
                        TextField("说明", text: $row.detail, axis: .vertical)
                            .lineLimit(2...4)
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
                    gearRows = []
                    gearUsesTemplate = true
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
    private var gallerySection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack() {
                    ForEach(Array(galleryNames.enumerated()), id: \.offset) { index, name in
                        if let url = CommunityPhotoStore.fileURL(named: name),
                           let uiImage = UIImage(contentsOfFile: url.path) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: PlatformMetrics.galleryEditorThumb, height: PlatformMetrics.galleryEditorThumb)
                                    .clipShape(PlatformMetrics.mediaShape)
                                Button {
                                    removeGalleryPhoto(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.55))
                                }
                                .offset(x: PlatformMetrics.galleryRemoveBadgeOffset, y: -PlatformMetrics.galleryRemoveBadgeOffset)
                            }
                        }
                    }

                    if galleryNames.count < 5 {
                        PhotosPicker(selection: $galleryPickerItems, maxSelectionCount: 5 - galleryNames.count, matching: .images) {
                            VStack() {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title3.weight(.bold))
                                Text("添加")
                                    .font(.caption)
                            }
                            .frame(width: PlatformMetrics.galleryEditorThumb, height: PlatformMetrics.galleryEditorThumb)
                            .background(PlatformSurface.thin, in: PlatformMetrics.mediaShape)
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

    private func prefill() {
        let existing = ActivityDetailContentStore.override(for: activity.id)
        hostNote = existing?.hostNote ?? ""
        prepNotesText = (existing?.prepNotes ?? []).joined(separator: "\n")
        registrationNotesText = (existing?.registrationNotes ?? []).joined(separator: "\n")
        feeIncludedText = (existing?.feeIncluded ?? []).joined(separator: "\n")
        feeExcludedText = (existing?.feeExcluded ?? []).joined(separator: "\n")
        refundNotesText = (existing?.refundNotes ?? []).joined(separator: "\n")
        galleryNames = existing?.galleryPhotoNames ?? []
        baselineGalleryNames = galleryNames

        if let saved = existing?.timeline, !saved.isEmpty {
            timelineRows = saved.map {
                TimelineDraftRow(time: $0.time, title: $0.title, detail: $0.detail)
            }
            timelineUsesTemplate = false
        } else {
            timelineRows = []
            timelineUsesTemplate = true
        }

        if let savedGear = existing?.gear, !savedGear.isEmpty {
            gearRows = savedGear.map {
                GearDraftRow(title: $0.title, detail: $0.detail, systemImage: $0.systemImage)
            }
            gearUsesTemplate = false
        } else {
            gearRows = []
            gearUsesTemplate = true
        }
    }

    private func defaultGearRows() -> [GearDraftRow] {
        ActivityDetailBlueprint.templateBlueprint(for: activity).gear.map {
            GearDraftRow(title: $0.title, detail: $0.detail, systemImage: $0.systemImage)
        }
    }

    private func defaultTimelineRows() -> [TimelineDraftRow] {
        ActivityDetailBlueprint.templateBlueprint(for: activity).timeline.map {
            TimelineDraftRow(time: $0.time, title: $0.title, detail: $0.detail)
        }
    }

    private func appendTimelineRow() {
        timelineUsesTemplate = false
        timelineRows.append(TimelineDraftRow(time: "10:00", title: "新环节", detail: "补充说明"))
    }

    private func deleteTimelineRows(at offsets: IndexSet) {
        timelineUsesTemplate = false
        timelineRows.remove(atOffsets: offsets)
    }

    private func deleteGearRows(at offsets: IndexSet) {
        gearUsesTemplate = false
        gearRows.remove(atOffsets: offsets)
    }

    private func removeGalleryPhoto(at index: Int) {
        guard galleryNames.indices.contains(index) else { return }
        // 先只改列表；保存时再删基线文件，取消时回收新增文件
        galleryNames.remove(at: index)
    }

    private func loadGalleryPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard galleryNames.count < 5,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let name = CommunityPhotoStore.saveJPEG(data)
            else { continue }
            galleryNames.append(name)
        }
        galleryPickerItems = []
    }

    private func discardUncommittedGalleryIfNeeded() {
        CommunityPhotoStore.discardUncommitted(current: galleryNames, baseline: baselineGalleryNames)
    }

    private func save() {
        didCommitSave = true
        CommunityPhotoStore.commitRemovals(current: galleryNames, baseline: baselineGalleryNames)

        let cleanedTimeline = timelineRows
            .map {
                TimelineDraftRow(
                    id: $0.id,
                    time: $0.time.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    detail: $0.detail.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.time.isEmpty && !$0.title.isEmpty }

        let timeline: [ActivityDetailContentOverride.PersistedTimelineItem]? =
            timelineUsesTemplate
            ? nil
            : (cleanedTimeline.isEmpty
                ? nil
                : cleanedTimeline.map { .init(time: $0.time, title: $0.title, detail: $0.detail) })

        let cleanedGear = gearRows
            .map {
                GearDraftRow(
                    id: $0.id,
                    title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    detail: $0.detail.trimmingCharacters(in: .whitespacesAndNewlines),
                    systemImage: $0.systemImage
                )
            }
            .filter { !$0.title.isEmpty && !$0.detail.isEmpty }

        let gear: [ActivityDetailContentOverride.PersistedGearItem]? =
            gearUsesTemplate
            ? nil
            : (cleanedGear.isEmpty
                ? nil
                : cleanedGear.map { .init(title: $0.title, detail: $0.detail, systemImage: $0.systemImage) })

        let override = ActivityDetailContentOverride(
            timeline: timeline,
            gear: gear,
            galleryPhotoNames: galleryNames.isEmpty ? nil : galleryNames,
            feeIncluded: lines(from: feeIncludedText),
            feeExcluded: lines(from: feeExcludedText),
            refundNotes: lines(from: refundNotesText),
            prepNotes: lines(from: prepNotesText),
            registrationNotes: lines(from: registrationNotesText),
            hostNote: hostNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        ActivityDetailContentStore.save(override, for: activity.id)
    }

    private func lines(from text: String) -> [String]? {
        let items = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return items.isEmpty ? nil : items
    }
}
