// Module: SparkLikes — Minimum profile before like/pass.

import PhotosUI
import SwiftUI

struct LikesViewerProfileGateSheet: View {
    @Bindable var viewModel: LikesFeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var hasPhoto: Bool = true
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingAvatar = false

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
                    if let avatarURL = viewModel.viewerProfile.avatarURL {
                        AsyncImage(url: avatarURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                ProgressView()
                            }
                        }
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                    }
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            String(
                                localized: "likes.profileGate.pickPhoto",
                                defaultValue: "选择头像照片",
                                comment: "Pick avatar photo"
                            ),
                            systemImage: "photo"
                        )
                    }
                    .disabled(isUploadingAvatar)
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
                                LikesViewerProfile(
                                    displayName: displayName,
                                    hasPhoto: hasPhoto,
                                    avatarURL: viewModel.viewerProfile.avatarURL
                                )
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
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    isUploadingAvatar = true
                    defer { isUploadingAvatar = false }
                    guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                    if await viewModel.uploadAvatarJPEG(data) {
                        hasPhoto = true
                    }
                }
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
