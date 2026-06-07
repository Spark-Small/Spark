// Module: SparkCommunity — Create post sheet state.

import Foundation
import Observation
import PhotosUI
import SparkCore
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
@Observable
public final class CreateCommunityPostViewModel {
    public enum PublishState: Equatable, Sendable {
        case idle
        case publishing
        case failure(String)
    }

    public var title = ""
    public var body = ""
    public var selectedPhotoItems: [PhotosPickerItem] = []
    public var selectedPreviewImages: [Image] = []
    public private(set) var publishState: PublishState = .idle

    private let createPost: any CreateCommunityPostUseCaseProtocol
    private let prepareMediaUpload: any PrepareCommunityMediaUploadUseCaseProtocol

    public init(
        createPost: any CreateCommunityPostUseCaseProtocol,
        prepareMediaUpload: any PrepareCommunityMediaUploadUseCaseProtocol
    ) {
        self.createPost = createPost
        self.prepareMediaUpload = prepareMediaUpload
    }

    public var canPublish: Bool {
        CreateCommunityPostDraft(title: title, body: body).isValid && !isPublishing
    }

    public var isPublishing: Bool {
        if case .publishing = publishState { return true }
        return false
    }

    public func loadSelectedMedia(from items: [PhotosPickerItem]) async {
        selectedPhotoItems = items
        var previews: [Image] = []
        for item in items {
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                continue
            }
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                previews.append(Image(uiImage: uiImage))
            }
        }
        selectedPreviewImages = previews
    }

    @discardableResult
    public func publish() async -> PublishedCommunityPostResult? {
        publishState = .publishing
        var draft = CreateCommunityPostDraft(title: title, body: body)
        do {
            draft.mediaItems = try await uploadSelectedMedia()
        } catch is CancellationError {
            publishState = .idle
            return nil
        } catch {
            publishState = .failure(error.localizedDescription)
            return nil
        }

        do {
            let post = try await createPost(draft)
            let result = PublishedCommunityPostResult(post: post, mediaItems: draft.mediaItems)
            title = ""
            body = ""
            selectedPhotoItems = []
            selectedPreviewImages = []
            publishState = .idle
            return result
        } catch is CancellationError {
            publishState = .idle
            return nil
        } catch {
            publishState = .failure(error.localizedDescription)
            return nil
        }
    }

    private func uploadSelectedMedia() async throws -> [SparkGalleryMedia] {
        var uploaded: [SparkGalleryMedia] = []
        for (index, item) in selectedPhotoItems.enumerated() {
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                if let movie = try await item.loadTransferable(type: PickedMovieFile.self) {
                    let media = try await prepareMediaUpload.uploadVideo(from: movie.url)
                    uploaded.append(
                        SparkGalleryMedia(
                            id: media.id,
                            url: media.url,
                            kind: .video,
                            posterURL: media.posterURL
                        )
                    )
                }
            } else if let data = try await item.loadTransferable(type: Data.self) {
                let url = try await prepareMediaUpload.uploadImage(data)
                uploaded.append(
                    SparkGalleryMedia(id: "upload-\(index)", url: url, kind: .image)
                )
            } else {
                throw CommunityError.underlying(
                    .unknown(
                        message: String(
                            localized: "community.compose.photoLoadFailed",
                            defaultValue: "无法读取所选媒体",
                            comment: "Media load failed"
                        )
                    )
                )
            }
        }
        return uploaded
    }

    public func dismissFailure() {
        if case .failure = publishState {
            publishState = .idle
        }
    }
}

private struct PickedMovieFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory
                .appending(path: "community-\(UUID().uuidString).mov")
            if FileManager.default.fileExists(atPath: destination.path()) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMovieFile(url: destination)
        }
    }
}
