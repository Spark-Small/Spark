// Module: SparkTrust — L1–L3 verification wizard (MVP).

import SparkDesignSystem
import SwiftUI

public struct TrustVerificationWizardView: View {
    public var repository: any TrustRepository
    public var onCompleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var profile: TrustProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init(repository: any TrustRepository, onCompleted: (() -> Void)? = nil) {
        self.repository = repository
        self.onCompleted = onCompleted
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let profile {
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
                                            Task { await verify(level) }
                                        }
                                        .disabled(isLoading)
                                    }
                                }
                            }
                        }
                    }
                } else if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    SparkRetryUnavailableView(
                        title: String(
                            localized: "trust.wizard.error.title",
                            defaultValue: "无法加载认证",
                            comment: "Wizard error"
                        ),
                        description: errorMessage
                    ) {
                        Task { await load() }
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
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            profile = try await repository.fetchProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func verify(_ level: TrustLevel) async {
        isLoading = true
        defer { isLoading = false }
        do {
            switch level {
            case .phone:
                profile = try await repository.verifyPhone()
            case .realName:
                profile = try await repository.verifyRealName()
            case .liveness:
                profile = try await repository.verifyLiveness()
            default:
                break
            }
            if profile?.nextMVPPendingLevel == nil {
                onCompleted?()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    TrustVerificationWizardView(repository: MockTrustRepository())
}
