// Module: SparkBuddy — Companion provider certification application form.

import SparkDesignSystem
import SwiftUI

public struct BuddyProviderApplicationView: View {
    @State private var viewModel: BuddyProviderApplicationViewModel
    @Environment(\.dismiss) private var dismiss
    private let onSubmitted: () -> Void

    public init(viewModel: BuddyProviderApplicationViewModel, onSubmitted: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onSubmitted = onSubmitted
    }

    public var body: some View {
        Form {
            Section {
                TextField(
                    String(localized: "buddy.provider.form.name", defaultValue: "展示昵称", comment: "Display name"),
                    text: $viewModel.displayName
                )
                TextField(
                    String(localized: "buddy.provider.form.city", defaultValue: "服务城市", comment: "City"),
                    text: $viewModel.city
                )
                Picker(
                    String(localized: "buddy.provider.form.category", defaultValue: "主打服务", comment: "Category"),
                    selection: $viewModel.serviceCategory
                ) {
                    ForEach(BuddyServiceCategory.allCases, id: \.self) { category in
                        Text(category.localizedTitle).tag(category)
                    }
                }
            } header: {
                Text(
                    String(localized: "buddy.provider.form.basic", defaultValue: "基本信息", comment: "Basic info")
                )
            }
            Section {
                TextField(
                    String(
                        localized: "buddy.provider.form.bio",
                        defaultValue: "自我介绍（至少 10 字）",
                        comment: "Bio"
                    ),
                    text: $viewModel.bio,
                    axis: .vertical
                )
                .lineLimit(4...8)
            } header: {
                Text(
                    String(localized: "buddy.provider.form.intro", defaultValue: "陪玩介绍", comment: "Intro section")
                )
            } footer: {
                Text(
                    String(
                        localized: "buddy.provider.form.trust.footer",
                        defaultValue: "需先完成「信任认证」中的实名与人脸核验。",
                        comment: "Trust prerequisite"
                    )
                )
            }
            Section {
                BuddyTagFlowRow(tags: viewModel.selectedTags)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.suggestedTags, id: \.self) { tag in
                            Button(tag) {
                                viewModel.toggleTag(tag)
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.selectedTags.contains(tag) ? Color.accentColor : .secondary)
                        }
                    }
                }
            } header: {
                Text(
                    String(localized: "buddy.provider.form.tags", defaultValue: "能力标签", comment: "Capability tags")
                )
            }
            if let message = viewModel.errorMessage {
                Section {
                    Text(message).foregroundStyle(.red).font(.caption)
                }
            }
            if viewModel.didSucceed {
                Section {
                    Label(
                        String(
                            localized: "buddy.provider.form.success",
                            defaultValue: "申请已提交，请等待平台审核",
                            comment: "Application success"
                        ),
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle(
            String(localized: "buddy.provider.form.title", defaultValue: "陪玩认证申请", comment: "Application title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task {
                    await viewModel.submit()
                    if viewModel.didSucceed {
                        onSubmitted()
                    }
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Text(
                            String(
                                localized: "buddy.provider.form.submit",
                                defaultValue: "提交认证申请",
                                comment: "Submit application"
                            )
                        )
                    }
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding + 2)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
            .background(.bar)
        }
        .onAppear {
            BuddyTelemetry.providerApplicationOpened()
        }
    }
}

#Preview {
    NavigationStack {
        BuddyProviderApplicationView(
            viewModel: BuddyProviderApplicationViewModel(
                submitApplication: SubmitBuddyProviderApplicationUseCase(repository: MockBuddyRepository())
            )
        )
    }
}
