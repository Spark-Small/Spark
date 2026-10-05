//
//  ActivityComposeSheet.swift
//  坐标系
//
//  发起 / 编辑活动：单页系统 Form（封面可选 · 必要成局字段 · 取消/下滑统一落盘）。
//

import PhotosUI
import SwiftUI
import CoordinateModels

struct ActivityComposeSheet: View {
    var editingActivity: Activity? = nil
    var onPublish: (ActivityComposePayload) -> Activity.ID?
    var onUpdate: ((Activity.ID, ActivityComposePayload) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppModel.self) private var app
    @State private var draft = ActivityComposeDraft()
    @State private var showMapPicker = false
    @State private var showPreview = false
    @State private var didCommitSave = false
    @State private var showDiscardEditsConfirm = false
    @FocusState private var focusedFeeField: FeeField?

    private enum FeeField: Hashable {
        case amount
        case aaEstimate
    }

    var body: some View {
        @Bindable var draft = draft

        NavigationStack {
            Form {
                coverSection
                basicsSection
                feeSection
                aboutSection
            }
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .background(PlatformSurface.groupedPage.ignoresSafeArea())
            .navigationTitle(
                draft.isEditing ? ActivityComposeCopy.editTitle : ActivityComposeCopy.createTitle
            )
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetCancellationToolbar(ActivityComposeCopy.cancel, action: requestCancel)
            .platformSheetConfirmationToolbar(
                draft.isEditing
                    ? ActivityComposeCopy.saveAction
                    : ActivityComposeCopy.publishAction,
                isEnabled: draft.canPublish,
                emphasizesWhenEnabled: true,
                action: openPreview
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(ActivityComposeCopy.keyboardDone) {
                        focusedFeeField = nil
                    }
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: draft.feeKind)
            .animation(reduceMotion ? nil : .snappy, value: draft.mediaNames)
            .animation(reduceMotion ? nil : .snappy, value: draft.canPublish)
            .sensoryFeedback(.success, trigger: draft.canPublish) { _, newValue in
                newValue
            }
            .navigationDestination(isPresented: $showPreview) {
                ActivityComposePublishPreviewView(
                    activity: draft.makePreviewActivity(
                        hostName: app.user.name,
                        existing: editingActivity
                    ),
                    galleryExtraNames: draft.galleryPhotoNames,
                    hostNote: draft.previewHostNote,
                    confirmTitle: draft.isEditing
                        ? ActivityComposeCopy.confirmSave
                        : ActivityComposeCopy.confirmPublish,
                    onConfirm: submit
                )
            }
        }
        .platformSheet(.form)
        .interactiveDismissDisabled(draft.isDirty)
        .platformFeedbackAlert($draft.moderationAlert)
        .confirmationDialog(
            draft.isEditing
                ? ActivityComposeCopy.discardEditsTitle
                : ActivityComposeCopy.discardCreateTitle,
            isPresented: $showDiscardEditsConfirm,
            titleVisibility: .visible
        ) {
            if draft.isEditing {
                Button(ActivityComposeCopy.discardEditsAction, role: .destructive) {
                    draft.discardUncommittedMediaIfNeeded()
                    didCommitSave = true
                    dismiss()
                }
            } else {
                Button(ActivityComposeCopy.saveDraftAndLeave) {
                    guard settleDismiss(allowModerationBlock: true) else { return }
                    app.activities.flashLight(ActivityComposeCopy.draftSaved)
                    didCommitSave = true
                    dismiss()
                }
                Button(ActivityComposeCopy.discardCreateAction, role: .destructive) {
                    draft.discardUncommittedMediaIfNeeded()
                    didCommitSave = true
                    dismiss()
                }
            }
            Button(ActivityComposeCopy.keepEditing, role: .cancel) {}
        }
        .onAppear { draft.prefill(from: editingActivity) }
        .onDisappear {
            guard !didCommitSave else { return }
            let shouldAnnounceDraft = draft.shouldPersistDraftOnCancel
            guard settleDismiss(allowModerationBlock: false) else { return }
            if shouldAnnounceDraft {
                app.activities.flashLight(ActivityComposeCopy.draftSaved)
            }
        }
        .sheet(isPresented: $showMapPicker) {
            ActivityMapPickerSheet(
                locationText: $draft.location,
                latitude: $draft.latitude,
                longitude: $draft.longitude
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .onChange(of: draft.mediaPickerItems) { _, items in
            Task { await draft.loadMedia(items, actorKey: app.user.name) }
        }
        .onChange(of: draft.date) { _, _ in
            draft.syncEndDate()
        }
    }

    // MARK: - Sections

    private var coverSection: some View {
        Section {
            if draft.canAddMedia {
                let mediaEmpty = draft.mediaNames.isEmpty
                PhotosPicker(
                    selection: $draft.mediaPickerItems,
                    maxSelectionCount: draft.remainingMediaSlots,
                    matching: LocalMediaLibrary.photosAndVideos,
                    photoLibrary: .shared()
                ) {
                    Label(
                        mediaEmpty
                            ? ActivityComposeCopy.addMedia
                            : ActivityComposeCopy.addMoreMedia,
                        systemImage: "photo.on.rectangle.angled"
                    )
                }
            }

            if !draft.mediaNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PlatformMetrics.minContentGap) {
                        ForEach(Array(draft.mediaNames.enumerated()), id: \.element) { index, name in
                            mediaThumb(name: name, index: index)
                        }
                    }
                }
            }

            if draft.isPreparingMedia {
                ProgressView(ActivityComposeCopy.preparingMedia)
            }
        } header: {
            Text(ActivityComposeCopy.coverSection)
        }
    }

    private func mediaThumb(name: String, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = draft.mediaPreviews[name] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    PlatformSurface.tertiaryFill
                }
            }
            .frame(
                width: PlatformMetrics.galleryEditorThumb,
                height: PlatformMetrics.galleryEditorThumb
            )
            .clipShape(PlatformMetrics.mediaShape)
            .overlay {
                if draft.isVideo(name) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if index == 0 {
                    Text(ActivityComposeCopy.coverBadge)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
                        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
                        .activityGlassCapsule(controlSize: .mini)
                        .padding(PlatformMetrics.captionBadgeInset)
                }
            }
            .accessibilityLabel(
                index == 0
                    ? (draft.isVideo(name)
                        ? "\(ActivityComposeCopy.coverBadge)，\(ActivityComposeCopy.videoBadge)"
                        : ActivityComposeCopy.coverBadge)
                    : (draft.isVideo(name) ? ActivityComposeCopy.videoBadge : ActivityComposeCopy.coverSection)
            )

            Button {
                draft.removeMedia(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .platformSymbolStyle(.mediaBadge)
            }
            .buttonStyle(.plain)
            .padding(PlatformMetrics.galleryRemoveBadgeOffset)
            .accessibilityLabel(ActivityComposeCopy.removeMedia)
        }
    }

    private var basicsSection: some View {
        Section {
            TextField(ActivityComposeCopy.titlePlaceholder, text: $draft.title)
                .platformFormTextInput(.singleLine)

            Picker(ActivityComposeCopy.categoryLabel, selection: $draft.category) {
                ForEach(draft.publishCategories) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .platformContentSymbolStyle()
                        .tag(item)
                }
            }

            TextField(ActivityComposeCopy.locationPlaceholder, text: $draft.location)
                .platformFormTextInput(.singleLine)

            Button {
                showMapPicker = true
            } label: {
                Label(
                    draft.latitude == nil
                        ? ActivityComposeCopy.mapPick
                        : ActivityComposeCopy.mapPicked,
                    systemImage: "map"
                )
                .platformContentSymbolStyle()
            }

            DatePicker(
                ActivityComposeCopy.startsLabel,
                selection: $draft.date,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .datePickerStyle(.compact)

            Stepper(
                "\(ActivityComposeCopy.capacityLabel) \(draft.capacity)",
                value: $draft.capacity,
                in: 2...40
            )
        } header: {
            Text(ActivityComposeCopy.basicsSection)
        }
    }

    private var feeSection: some View {
        Section {
            Picker(ActivityComposeCopy.feeKindLabel, selection: $draft.feeKind) {
                ForEach(ActivityComposeFeeKind.allCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage)
                        .platformContentSymbolStyle()
                        .tag(kind)
                }
            }
            .pickerStyle(.menu)

            if draft.feeKind == .paid {
                LabeledContent(ActivityComposeCopy.feeAmountLabel) {
                    TextField(ActivityComposeCopy.feeAmountPlaceholder, text: $draft.feeAmountText)
                        .platformFormTextInput(.decimalAmount)
                        .focused($focusedFeeField, equals: .amount)
                }
                .transition(.opacity)
            }

            if draft.feeKind == .venueAA {
                LabeledContent(ActivityComposeCopy.feeAAEstimateLabel) {
                    TextField(
                        ActivityComposeCopy.feeAAEstimatePlaceholder,
                        text: $draft.feeAAEstimateText
                    )
                    .platformFormTextInput(.trailingLooseAmount)
                    .focused($focusedFeeField, equals: .aaEstimate)
                }
                .transition(.opacity)
            }
        } header: {
            Text(ActivityComposeCopy.feeSection)
        }
    }

    private var aboutSection: some View {
        Section {
            TextField(
                ActivityComposeCopy.summaryPlaceholder,
                text: $draft.summary,
                axis: .vertical
            )
            .platformFormTextInput(.body)
        } header: {
            Text(ActivityComposeCopy.aboutSection)
        } footer: {
            if let footer = draft.publishBlockerFooter {
                Text(footer)
            }
        }
    }

    // MARK: - Actions

    private func openPreview() {
        if let reason = draft.moderationBlockReason() {
            draft.moderationAlert = reason
            return
        }
        focusedFeeField = nil
        draft.syncEndDate()
        showPreview = true
    }

    private func requestCancel() {
        if draft.isDirty {
            showDiscardEditsConfirm = true
            return
        }
        guard settleDismiss(allowModerationBlock: true) else { return }
        dismiss()
    }

    /// - Returns: `false` 表示被审核拦住、应留在页内。
    @discardableResult
    private func settleDismiss(allowModerationBlock: Bool) -> Bool {
        if draft.shouldPersistDraftOnCancel {
            if allowModerationBlock, let reason = draft.moderationBlockReason() {
                draft.moderationAlert = reason
                return false
            }
            _ = draft.saveDraftSnapshot()
        } else {
            draft.discardUncommittedMediaIfNeeded()
        }
        didCommitSave = true
        return true
    }

    private func submit() {
        if let reason = draft.moderationBlockReason() {
            draft.moderationAlert = reason
            return
        }
        draft.syncEndDate()
        draft.commitMediaRemovalsIfNeeded()
        didCommitSave = true

        let payload = draft.makePayload
        if let id = draft.editingActivityID, let onUpdate {
            onUpdate(id, payload)
            draft.persistContentOverride(for: id)
        } else if let id = onPublish(payload) {
            draft.persistContentOverride(for: id)
            draft.clearDraftStoreAfterPublish()
        }
        dismiss()
    }
}
