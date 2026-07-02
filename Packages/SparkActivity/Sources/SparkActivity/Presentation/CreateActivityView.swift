// Module: SparkActivity — Host publishes a new activity (Meetup-style create flow).

import SparkDesignSystem
import SwiftUI

public struct CreateActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateActivityViewModel
    @State private var showsPreviewSheet = false
    @State private var showsSaveTemplateAlert = false
    @State private var saveTemplateName = ""
    @State private var templateSavedFeedback: String?
    private let onCreated: (ActivityDetail) -> Void
    private let onProvisionGroupChat: ((ActivityDetail) async -> Void)?

    public init(
        viewModel: CreateActivityViewModel,
        onCreated: @escaping (ActivityDetail) -> Void,
        onProvisionGroupChat: ((ActivityDetail) async -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onCreated = onCreated
        self.onProvisionGroupChat = onProvisionGroupChat
    }

    public init(
        coordinator: ActivityCoordinator,
        initialDraft: CreateActivityDraft? = nil,
        templateStore: ActivityCreateTemplateStore = ActivityCreateTemplateStore(),
        onCreated: @escaping (ActivityDetail) -> Void,
        onProvisionGroupChat: ((ActivityDetail) async -> Void)? = nil
    ) {
        self.init(
            viewModel: coordinator.makeCreateViewModel(initialDraft: initialDraft, templateStore: templateStore),
            onCreated: onCreated,
            onProvisionGroupChat: onProvisionGroupChat
        )
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            ActivityCreateFormFields(
                draft: $viewModel.draft,
                selectedCoverItems: $viewModel.selectedCoverItems,
                coverPreviewImage: viewModel.coverPreviewImage,
                coverIsVideo: viewModel.coverIsVideo,
                submitErrorMessage: submitErrorMessage,
                showsValidationGuidance: viewModel.showsValidationGuidance,
                savedTemplates: viewModel.savedTemplates,
                canSaveAsTemplate: viewModel.canSaveAsTemplate,
                onQuickTemplateSelected: { template in
                    viewModel.applyQuickTemplate(template)
                },
                onSavedTemplateSelected: { template in
                    viewModel.applySavedTemplate(template)
                },
                onSaveCurrentAsTemplate: {
                    saveTemplateName = viewModel.draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    showsSaveTemplateAlert = true
                },
                onRemoveSavedTemplate: { id in
                    viewModel.removeSavedTemplate(id: id)
                }
            )
        }
        .sparkDismissesKeyboardOnScroll()
        .accessibilityElement(children: .contain)
        .navigationTitle(
            String(localized: "activity.create.title.screen", defaultValue: "发起活动", comment: "Create screen")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .confirmationAction) {
                Button {
                    viewModel.markPublishAttempted()
                    showsPreviewSheet = true
                } label: {
                    Text(
                        String(localized: "activity.create.preview", defaultValue: "预览", comment: "Preview activity")
                    )
                }
                .disabled(!viewModel.canPreview || isSubmitting)
                .accessibilityHint(previewAccessibilityHint)

                Button {
                    Task { await publish() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .accessibilityLabel(
                                String(
                                    localized: "activity.create.publishing.a11y",
                                    defaultValue: "正在发布活动",
                                    comment: "Publishing a11y"
                                )
                            )
                    } else {
                        Text(
                            String(localized: "activity.create.publish", defaultValue: "发布", comment: "Publish activity")
                        )
                    }
                }
                .disabled(!viewModel.canPublish || isSubmitting)
                .accessibilityHint(publishAccessibilityHint)
            }
        }
        .disabled(isSubmitting)
        .onChange(of: viewModel.selectedCoverItems) { _, _ in
            Task { await viewModel.loadSelectedCover() }
        }
        .sheet(isPresented: $showsPreviewSheet) {
            ActivityCreatePreviewSheet(viewModel: viewModel)
        }
        .alert(
            String(
                localized: "activity.create.template.save.title",
                defaultValue: "保存为模版",
                comment: "Save template alert title"
            ),
            isPresented: $showsSaveTemplateAlert
        ) {
            TextField(
                String(
                    localized: "activity.create.template.save.name",
                    defaultValue: "模版名称",
                    comment: "Template name field"
                ),
                text: $saveTemplateName
            )
            Button(String(localized: "action.save", defaultValue: "保存", comment: "Save")) {
                if viewModel.saveCurrentAsTemplate(named: saveTemplateName) != nil {
                    templateSavedFeedback = String(
                        localized: "activity.create.template.save.success",
                        defaultValue: "模版已保存",
                        comment: "Template saved"
                    )
                }
            }
            Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel"), role: .cancel) {}
        }
        .alert(
            String(localized: "activity.create.template.save.success", defaultValue: "模版已保存", comment: "Template saved"),
            isPresented: Binding(
                get: { templateSavedFeedback != nil },
                set: { if !$0 { templateSavedFeedback = nil } }
            )
        ) {
            Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                templateSavedFeedback = nil
            }
        }
    }

    private var isSubmitting: Bool {
        if case .submitting = viewModel.submitState { return true }
        return false
    }

    private var submitErrorMessage: String? {
        if case .failure(let message) = viewModel.submitState {
            return message
        }
        return nil
    }

    private var previewAccessibilityHint: String {
        if viewModel.canPreview {
            return String(
                localized: "activity.create.preview.hint",
                defaultValue: "查看活动发布后的展示效果",
                comment: "Preview hint"
            )
        }
        return incompleteFormHint
    }

    private var publishAccessibilityHint: String {
        if viewModel.canPublish {
            return String(
                localized: "activity.create.publish.hint",
                defaultValue: "发布活动给想见面的人",
                comment: "Publish hint"
            )
        }
        return incompleteFormHint
    }

    private var incompleteFormHint: String {
        if !viewModel.hasSelectedCover {
            return String(
                localized: "activity.create.cover.required",
                defaultValue: "请先上传局封面",
                comment: "Cover required guidance"
            )
        }
        return viewModel.draft.validationError?.errorDescription
            ?? String(
                localized: "activity.create.publish.disabled",
                defaultValue: "填好局名和集合地点即可发布",
                comment: "Publish disabled hint"
            )
    }

    private func publish() async {
        viewModel.markPublishAttempted()
        guard let detail = await viewModel.submit() else { return }
        if let onProvisionGroupChat {
            await onProvisionGroupChat(detail)
        }
        onCreated(detail)
        dismiss()
    }
}

#Preview("Empty") {
    NavigationStack {
        CreateActivityView(coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository())) { _ in }
    }
}

#Preview("Match coffee draft") {
    NavigationStack {
        CreateActivityView(
            coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()),
            initialDraft: .matchCoffee(peerName: "Mia")
        ) { _ in }
    }
}

#Preview("Dark") {
    NavigationStack {
        CreateActivityView(coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository())) { _ in }
    }
    .preferredColorScheme(.dark)
}
