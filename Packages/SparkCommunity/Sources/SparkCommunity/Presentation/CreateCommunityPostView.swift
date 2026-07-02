// Module: SparkCommunity — Compose new community post (MODULE-E).

import PhotosUI
import SparkCore
import SparkDesignSystem
import SwiftUI

public struct CreateCommunityPostView: View {
    @Bindable var viewModel: CreateCommunityPostViewModel
    let onCancel: () -> Void
    let onPublished: (PublishedCommunityPostResult) -> Void

    public init(
        viewModel: CreateCommunityPostViewModel,
        onCancel: @escaping () -> Void,
        onPublished: @escaping (PublishedCommunityPostResult) -> Void
    ) {
        self.viewModel = viewModel
        self.onCancel = onCancel
        self.onPublished = onPublished
    }

    public var body: some View {
        Form {
            Section {
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .videos]),
                    photoLibrary: .shared()
                ) {
                    if viewModel.selectedPreviewImages.isEmpty, viewModel.selectedPhotoItems.isEmpty {
                        Label(
                            String(
                                localized: "community.compose.addMedia",
                                defaultValue: "添加照片或视频",
                                comment: "Add photo or video"
                            ),
                            systemImage: "photo.on.rectangle"
                        )
                    } else if viewModel.selectedPreviewImages.count == 1,
                              viewModel.selectedPhotoItems.count == 1 {
                        viewModel.selectedPreviewImages[0]
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius,
                                    style: .continuous
                                )
                            )
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(
                                String(
                                    format: String(
                                        localized: "community.compose.mediaCount.format",
                                        defaultValue: "已选 %lld 个媒体",
                                        comment: "Selected media count"
                                    ),
                                    locale: .current,
                                    viewModel.selectedPhotoItems.count
                                )
                            )
                            .font(.subheadline.weight(.semibold))
                            if !viewModel.selectedPreviewImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(viewModel.selectedPreviewImages.enumerated()), id: \.offset) { _, image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(
                                                    width: SparkLayoutMetrics.composeMediaThumbnailSize,
                                                    height: SparkLayoutMetrics.composeMediaThumbnailSize
                                                )
                                                .clipShape(
                                                    RoundedRectangle(
                                                        cornerRadius: SparkLayoutMetrics.composeMediaThumbnailCornerRadius,
                                                        style: .continuous
                                                    )
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    SparkPermissionTelemetry.trackPhotoLibraryAccess(source: .communityCreatePost)
                }
                .onChange(of: viewModel.selectedPhotoItems) { _, items in
                    Task { await viewModel.loadSelectedMedia(from: items) }
                }
            } footer: {
                Text(
                    String(
                        localized: "community.compose.media.footer",
                        defaultValue: "最多 10 个照片或视频，发布后可左右滑动查看。",
                        comment: "Compose media footer"
                    )
                )
            }

            Section {
                TextField(
                    String(
                        localized: "community.compose.title",
                        defaultValue: "标题",
                        comment: "Post title"
                    ),
                    text: $viewModel.title
                )
                TextEditor(text: $viewModel.body)
                    .frame(minHeight: 120)
                    .accessibilityLabel(
                        String(
                            localized: "community.compose.body.a11y",
                            defaultValue: "正文",
                            comment: "Post body"
                        )
                    )
            } footer: {
                Text(
                    String(
                        localized: "community.compose.footer",
                        defaultValue: "请遵守社区规范，勿发布违法或骚扰内容。",
                        comment: "Compose footer"
                    )
                )
            }

            if case .failure(let message) = viewModel.publishState {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .sparkDismissesKeyboardOnScroll()
        .navigationTitle(
            String(localized: "community.compose.title.nav", defaultValue: "发帖", comment: "Compose nav title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                    onCancel()
                }
                .disabled(viewModel.isPublishing)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "community.compose.publish", defaultValue: "发布", comment: "Publish")) {
                    Task {
                        if let result = await viewModel.publish() {
                            onPublished(result)
                        }
                    }
                }
                .disabled(!viewModel.canPublish)
            }
        }
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Create post") {
        NavigationStack {
            CreateCommunityPostView(
                viewModel: CreateCommunityPostViewModel(
                    createPost: CreateCommunityPostUseCase(repository: MockCommunityPostsRepository()),
                    prepareMediaUpload: PrepareCommunityMediaUploadUseCase()
                ),
                onCancel: {},
                onPublished: { _ in }
            )
        }
    }
}
