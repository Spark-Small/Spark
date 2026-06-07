// Module: SparkTrust — L1–L3 verification wizard (MVP).

import SparkDesignSystem
import SwiftUI

public struct TrustVerificationWizardView: View {
    @State private var viewModel: TrustVerificationViewModel
    public var onCompleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    public init(repository: any TrustRepository, onCompleted: (() -> Void)? = nil) {
        let model = TrustVerificationViewModel(repository: repository)
        model.onCompleted = onCompleted
        _viewModel = State(initialValue: model)
        self.onCompleted = onCompleted
    }

    public init(viewModel: TrustVerificationViewModel, onCompleted: (() -> Void)? = nil) {
        viewModel.onCompleted = onCompleted
        _viewModel = State(initialValue: viewModel)
        self.onCompleted = onCompleted
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let profile = viewModel.profile {
                    List {
                        Section {
                            TrustScoreRingView(profile: profile)
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                        }
                        Section(
                            String(
                                localized: "trust.wizard.section",
                                defaultValue: "认证进度",
                                comment: "Verification section"
                            )
                        ) {
                            ForEach(TrustLevel.mvpLevels) { level in
                                HStack {
                                    Text(level.localizedTitle)
                                    Spacer()
                                    if profile.completedLevels.contains(level) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Button(
                                            String(
                                                localized: "trust.wizard.verify",
                                                defaultValue: "去认证",
                                                comment: "Verify CTA"
                                            )
                                        ) {
                                            Task { await viewModel.verify(level) }
                                        }
                                        .disabled(viewModel.isLoading)
                                    }
                                }
                            }
                        }
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    SparkRetryUnavailableView(
                        title: String(
                            localized: "trust.wizard.error.title",
                            defaultValue: "无法加载认证",
                            comment: "Wizard error"
                        ),
                        description: errorMessage
                    ) {
                        Task { await viewModel.load() }
                    }
                }
            }
            .navigationTitle(
                String(localized: "trust.wizard.title", defaultValue: "信任认证", comment: "Wizard title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                        dismiss()
                    }
                }
            }
            .task { await viewModel.load() }
        }
    }
}

#Preview {
    TrustVerificationWizardView(repository: MockTrustRepository())
}
