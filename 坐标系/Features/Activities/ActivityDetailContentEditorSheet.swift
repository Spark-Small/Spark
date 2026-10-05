//
//  ActivityDetailContentEditorSheet.swift
//  坐标系
//
//  发起人写实编辑：行程 / 须知 / 补充说明。
//  行程·装备·图库 Section 见 `+FormSections`。
//

import PhotosUI
import SwiftUI
import CoordinateModels

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
    // 跨文件 +FormSections 需 internal。
    @State var timelineRows: [TimelineDraftRow] = []
    @State var gearRows: [GearDraftRow] = []
    @State var galleryNames: [String] = []
    @State private var baselineGalleryNames: [String] = []
    @State var galleryPickerItems: [PhotosPickerItem] = []
    @State private var didCommitSave = false
    /// 恢复类别默认：保存时 timeline / gear 写 nil，不固化模板副本
    @State var timelineUsesTemplate = false
    @State var gearUsesTemplate = false
    @State var restoreConfirmTarget: RestoreDefaultsTarget?

    enum RestoreDefaultsTarget: Identifiable {
        case timeline
        case gear

        var id: String {
            switch self {
            case .timeline: "timeline"
            case .gear: "gear"
            }
        }

        var dialogTitle: String {
            switch self {
            case .timeline: "恢复类别默认行程？"
            case .gear: "恢复类别默认装备？"
            }
        }

        var confirmTitle: String {
            switch self {
            case .timeline: "恢复默认行程"
            case .gear: "恢复默认装备"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                gallerySection
                timelineSection
                gearSection
                notesSections
            }
            .navigationTitle(ActivityCardStatus.refineContent)
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetCancellationToolbar(ActivityComposeCopy.cancel) {
                discardUncommittedGalleryIfNeeded()
                dismiss()
            }
            .platformSheetConfirmationToolbar(
                ActivityComposeCopy.saveAction,
                emphasizesWhenEnabled: true
            ) {
                save()
                onSaved()
                dismiss()
            }
            .onAppear(perform: prefill)
            .onDisappear {
                if !didCommitSave {
                    discardUncommittedGalleryIfNeeded()
                }
            }
            .confirmationDialog(
                restoreConfirmTarget?.dialogTitle ?? "",
                isPresented: Binding(
                    get: { restoreConfirmTarget != nil },
                    set: { if !$0 { restoreConfirmTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let restoreConfirmTarget {
                    Button(restoreConfirmTarget.confirmTitle, role: .destructive) {
                        applyRestoreDefaults(restoreConfirmTarget)
                        self.restoreConfirmTarget = nil
                    }
                }
                Button(ActivityComposeCopy.cancel, role: .cancel) {
                    restoreConfirmTarget = nil
                }
            } message: {
                Text(ActivityDetailCopy.contentEditorRestoreDefaultsMessage)
            }
        }
        .platformSheet(.form)
    }

    @ViewBuilder
    private var notesSections: some View {
        Section {
            TextField("补充说明（展示在决策卡）", text: $hostNote, axis: .vertical)
                .platformFormTextInput(.caption)
        } header: {
            Text("发起人补充")
        }

        Section("准备 / 风险提示（每行一条）") {
            TextField("例如：请自备饮水", text: $prepNotesText, axis: .vertical)
                .platformFormTextInput(.body)
        }

        Section(ActivityDetailCopy.notesEditorSection) {
            TextField("例如：开始前 6 小时可取消", text: $registrationNotesText, axis: .vertical)
                .platformFormTextInput(.body)
        }

        Section("\(ActivityDetailCopy.feeIncludedTitle)（每行一条）") {
            TextField("例如：场地协调", text: $feeIncludedText, axis: .vertical)
                .platformFormTextInput(.note)
        }

        Section("\(ActivityDetailCopy.feeExcludedTitle)（每行一条）") {
            TextField("例如：个人交通", text: $feeExcludedText, axis: .vertical)
                .platformFormTextInput(.note)
        }

        Section("\(ActivityDetailCopy.feeRefundPolicyTitle)（每行一条）") {
            TextField("例如：开始前 24 小时可取消", text: $refundNotesText, axis: .vertical)
                .platformFormTextInput(.note)
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

    func discardUncommittedGalleryIfNeeded() {
        LocalMediaLibrary.discardUncommitted(current: galleryNames, baseline: baselineGalleryNames)
    }

    private func applyRestoreDefaults(_ target: RestoreDefaultsTarget) {
        switch target {
        case .timeline:
            timelineRows = []
            timelineUsesTemplate = true
        case .gear:
            gearRows = []
            gearUsesTemplate = true
        }
    }

    private func save() {
        didCommitSave = true
        LocalMediaLibrary.commitRemovals(current: galleryNames, baseline: baselineGalleryNames)

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
