// Module: SparkActivity — Host publishes a new activity (Meetup-style create flow).

import SparkDesignSystem
import SwiftUI

public struct CreateActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateActivityViewModel
    private let onCreated: (ActivityDetail) -> Void
    private let onProvisionGroupChat: ((ActivityDetail) async -> Void)?

    public init(
        repository: any ActivityFeedRepository,
        initialDraft: CreateActivityDraft? = nil,
        onCreated: @escaping (ActivityDetail) -> Void,
        onProvisionGroupChat: ((ActivityDetail) async -> Void)? = nil
    ) {
        let viewModel = CreateActivityViewModel(repository: repository)
        if let initialDraft {
            viewModel.draft = initialDraft
        }
        _viewModel = State(initialValue: viewModel)
        self.onCreated = onCreated
        self.onProvisionGroupChat = onProvisionGroupChat
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
        .navigationTitle(
            String(localized: "activity.create.title.screen", defaultValue: "创建活动", comment: "Create screen")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "activity.create.publish", defaultValue: "发布", comment: "Publish")) {
                    Task { await publish() }
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

    private func publish() async {
        guard let detail = await viewModel.submit() else { return }
        if let onProvisionGroupChat {
            await onProvisionGroupChat(detail)
        }
        onCreated(detail)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CreateActivityView(repository: MockActivityFeedRepository()) { _ in }
    }
}
