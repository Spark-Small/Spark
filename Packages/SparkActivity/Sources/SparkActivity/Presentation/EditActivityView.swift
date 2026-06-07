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
            Section {
                TextField(
                    String(localized: "activity.create.title", defaultValue: "活动名称", comment: "Create field"),
                    text: $viewModel.draft.title
                )
                TextField(
                    String(localized: "activity.create.location", defaultValue: "地点", comment: "Create field"),
                    text: $viewModel.draft.locationName
                )
                DatePicker(
                    String(localized: "activity.create.startsAt", defaultValue: "开始时间", comment: "Create field"),
                    selection: $viewModel.draft.startsAt
                )
                Stepper(
                    capacityLabel,
                    value: Binding(
                        get: { viewModel.draft.capacity ?? 10 },
                        set: { viewModel.draft.capacity = $0 }
                    ),
                    in: 2 ... 99
                )
            } header: {
                Text(
                    String(localized: "activity.create.section.basics", defaultValue: "基本信息", comment: "Create section")
                )
            }

            Section {
                TextField(
                    String(localized: "activity.create.description", defaultValue: "活动说明", comment: "Create field"),
                    text: $viewModel.draft.description,
                    axis: .vertical
                )
                .lineLimit(4 ... 8)
            } header: {
                Text(
                    String(localized: "activity.create.section.about", defaultValue: "说明", comment: "Create section")
                )
            }

            if case .failure(let message) = viewModel.submitState {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
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
                Button(String(localized: "action.save", defaultValue: "保存", comment: "Save")) {
                    Task { await save() }
                }
                .disabled(!viewModel.draft.isValid || isSubmitting)
            }
        }
        .disabled(isSubmitting)
    }

    private var isSubmitting: Bool {
        if case .submitting = viewModel.submitState { return true }
        return false
    }

    private var capacityLabel: String {
        String(localized: "activity.create.capacity", defaultValue: "人数上限", comment: "Capacity stepper")
    }

    private func save() async {
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
