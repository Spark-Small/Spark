// Module: SparkLikes — Minimum profile before like/pass.

import SwiftUI

struct LikesViewerProfileGateSheet: View {
    @Bindable var viewModel: LikesFeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var hasPhoto: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                if let error = viewModel.profileGateSaveError {
                    Section {
                        Text(error.displayText)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
                Section {
                    TextField(
                        String(
                            localized: "likes.profileGate.name",
                            defaultValue: "昵称",
                            comment: "Display name"
                        ),
                        text: $displayName
                    )
                    Toggle(
                        String(
                            localized: "likes.profileGate.photo",
                            defaultValue: "已上传至少一张照片",
                            comment: "Has photo toggle"
                        ),
                        isOn: $hasPhoto
                    )
                } footer: {
                    Text(
                        String(
                            localized: "likes.profileGate.footer",
                            defaultValue: "完善资料后，其他用户也能更好地了解你",
                            comment: "Profile gate footer"
                        )
                    )
                }
            }
            .navigationTitle(
                String(
                    localized: "likes.profileGate.title",
                    defaultValue: "完善资料",
                    comment: "Profile gate title"
                )
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
                        Task {
                            let saved = await viewModel.saveViewerProfile(
                                LikesViewerProfile(displayName: displayName, hasPhoto: hasPhoto)
                            )
                            if saved {
                                dismiss()
                            }
                        }
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasPhoto)
                }
            }
            .onAppear {
                displayName = viewModel.viewerProfile.displayName
                hasPhoto = viewModel.viewerProfile.hasPhoto
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LikesViewerProfileGateSheet(viewModel: LikesFeedViewModel(repository: MockLikesFeedRepository()))
}

#Preview("Profile gate — dark") {
    LikesPreviewSupport.darkMode {
        LikesViewerProfileGateSheet(viewModel: LikesFeedViewModel(repository: MockLikesFeedRepository()))
    }
}
