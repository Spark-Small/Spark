// Module: SparkActivity — Host edits activity basics.

import SparkDesignSystem
import SwiftUI

public struct EditActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditActivityViewModel
    private let onSaved: (ActivityDetail) -> Void

    public init(
        viewModel: EditActivityViewModel,
        onSaved: @escaping (ActivityDetail) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    public init(
        activity: ActivityDetail,
        coordinator: ActivityCoordinator,
        onSaved: @escaping (ActivityDetail) -> Void
    ) {
        self.init(
            viewModel: coordinator.makeEditViewModel(activity: activity),
            onSaved: onSaved
        )
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            ActivityCreateFormFields(
                draft: $viewModel.draft,
                selectedCoverItems: .constant([]),
                coverPreviewImage: nil,
                coverIsVideo: false,
                submitErrorMessage: submitErrorMessage,
                showsValidationGuidance: viewModel.showsValidationGuidance,
                showsQuickTemplates: false,
                showsCoverPicker: false,
                showsProgress: false
            )
        }
        .sparkDismissesKeyboardOnScroll()
        .accessibilityElement(children: .contain)
        .navigationTitle(
            String(localized: "activity.edit.title", defaultValue: "编辑活动", comment: "Edit screen")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await save() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .accessibilityLabel(
                                String(
                                    localized: "activity.edit.saving.a11y",
                                    defaultValue: "正在保存活动",
                                    comment: "Saving a11y"
                                )
                            )
                    } else {
                        Text(String(localized: "action.save", defaultValue: "保存", comment: "Save"))
                    }
                }
                .disabled(!viewModel.draft.isValid || isSubmitting || !viewModel.hasChanges)
                .accessibilityHint(
                    saveAccessibilityHint
                )
            }
        }
        .disabled(isSubmitting)
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

    private var saveAccessibilityHint: String {
        if !viewModel.hasChanges {
            return String(
                localized: "activity.edit.save.unchanged",
                defaultValue: "内容未修改",
                comment: "Save unchanged hint"
            )
        }
        if viewModel.draft.isValid {
            return String(
                localized: "activity.edit.save.hint",
                defaultValue: "保存后参加者将看到更新内容",
                comment: "Save hint"
            )
        }
        return viewModel.draft.validationError?.errorDescription
            ?? String(
                localized: "activity.create.publish.disabled",
                defaultValue: "填好局名和集合地点即可预览",
                comment: "Publish disabled hint"
            )
    }

    private func save() async {
        viewModel.markSaveAttempted()
        guard let detail = await viewModel.submit() else { return }
        onSaved(detail)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        if let activity = MockActivityCatalog.detail(id: "act_1") {
            EditActivityView(
                activity: activity,
                coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()),
                onSaved: { _ in }
            )
        }
    }
}

#Preview("Dark") {
    NavigationStack {
        if let activity = MockActivityCatalog.detail(id: "act_1") {
            EditActivityView(
                activity: activity,
                coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()),
                onSaved: { _ in }
            )
        }
    }
    .preferredColorScheme(.dark)
}
