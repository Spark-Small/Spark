// Module: SparkActivity — Create activity form state.

import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
@Observable
public final class CreateActivityViewModel {
    public enum SubmitState: Equatable, Sendable {
        case idle
        case submitting
        case failure(String)
    }

    public var draft = CreateActivityDraft()
    public var selectedCoverItems: [PhotosPickerItem] = []
    public var coverPreviewImage: Image?
    public var coverIsVideo = false
    public private(set) var submitState: SubmitState = .idle
    public private(set) var hasAttemptedPublish = false

    private let createActivity: any CreateActivityUseCaseProtocol
    private let prepareCoverUpload: any PrepareActivityCoverUploadUseCaseProtocol
    let templateStore: ActivityCreateTemplateStore

    public init(
        createActivity: any CreateActivityUseCaseProtocol,
        prepareCoverUpload: any PrepareActivityCoverUploadUseCaseProtocol = PrepareActivityCoverUploadUseCase(),
        templateStore: ActivityCreateTemplateStore = ActivityCreateTemplateStore()
    ) {
        self.createActivity = createActivity
        self.prepareCoverUpload = prepareCoverUpload
        self.templateStore = templateStore
    }

    public convenience init(
        repository: any ActivityFeedRepository,
        templateStore: ActivityCreateTemplateStore = ActivityCreateTemplateStore()
    ) {
        self.init(createActivity: CreateActivityUseCase(repository: repository), templateStore: templateStore)
    }

    public var showsValidationGuidance: Bool {
        hasAttemptedPublish || hasPartialDraft
    }

    public var canPreview: Bool {
        draft.isValid && hasSelectedCover
    }

    public var canPublish: Bool {
        canPreview
    }

    /// Backward-compatible alias.
    public var canPreviewPublish: Bool { canPreview }

    public var canSaveAsTemplate: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var savedTemplates: [ActivityCreateSavedTemplate] {
        templateStore.savedTemplates
    }

    public var hasSelectedCover: Bool {
        !selectedCoverItems.isEmpty
    }

    public func markPublishAttempted() {
        hasAttemptedPublish = true
    }

    public func applyQuickTemplate(_ template: ActivityCreateQuickTemplate) {
        template.apply(to: &draft)
    }

    public func applySavedTemplate(_ template: ActivityCreateSavedTemplate) {
        template.apply(to: &draft)
    }

    @discardableResult
    public func saveCurrentAsTemplate(named name: String) -> ActivityCreateSavedTemplate? {
        templateStore.saveCustom(from: draft, name: name)
    }

    public func removeSavedTemplate(id: String) {
        templateStore.remove(id: id)
    }

    public func loadSelectedCover() async {
        guard let item = selectedCoverItems.first else {
            coverPreviewImage = nil
            coverIsVideo = false
            return
        }

        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            coverIsVideo = true
            if let movie = try? await item.loadTransferable(type: PickedActivityCoverMovie.self),
               let posterData = try? Data(contentsOf: movie.url),
               let uiImage = UIImage(data: posterData) {
                coverPreviewImage = Image(uiImage: uiImage)
            } else {
                coverPreviewImage = nil
            }
            return
        }

        coverIsVideo = false
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            coverPreviewImage = Image(uiImage: uiImage)
        } else {
            coverPreviewImage = nil
        }
    }

    public func submit() async -> ActivityDetail? {
        guard canPublish else { return nil }
        submitState = .submitting
        do {
            var publishDraft = draft.normalizedForPublish()
            publishDraft = try await attachUploadedCover(to: publishDraft)
            let detail = try await createActivity(draft: publishDraft)
            submitState = .idle
            return detail
        } catch is CancellationError {
            submitState = .idle
            return nil
        } catch let error as ActivityError {
            submitState = .failure(error.errorDescription ?? error.localizedDescription)
            return nil
        } catch {
            submitState = .failure(error.localizedDescription)
            return nil
        }
    }

    private func attachUploadedCover(to draft: CreateActivityDraft) async throws -> CreateActivityDraft {
        guard let item = selectedCoverItems.first else { return draft }
        var updated = draft
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            guard let movie = try await item.loadTransferable(type: PickedActivityCoverMovie.self) else {
                throw ActivityError.underlying(
                    .unknown(
                        message: String(
                            localized: "activity.create.cover.videoLoadFailed",
                            defaultValue: "无法读取所选视频",
                            comment: "Video load failed"
                        )
                    )
                )
            }
            let uploaded = try await prepareCoverUpload.uploadVideo(from: movie.url)
            updated.coverURL = uploaded.url
            updated.coverPosterURL = uploaded.posterURL
            updated.coverIsVideo = uploaded.isVideo
        } else if let data = try await item.loadTransferable(type: Data.self) {
            let uploaded = try await prepareCoverUpload.uploadImage(data)
            updated.coverURL = uploaded.url
            updated.coverPosterURL = uploaded.posterURL
            updated.coverIsVideo = uploaded.isVideo
        } else {
            throw ActivityError.underlying(
                .unknown(
                    message: String(
                        localized: "activity.create.cover.imageLoadFailed",
                        defaultValue: "无法读取所选图片",
                        comment: "Image load failed"
                    )
                )
            )
        }
        return updated
    }

    private var hasPartialDraft: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || hasSelectedCover
    }
}

private struct PickedActivityCoverMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory
                .appending(path: "activity-cover-\(UUID().uuidString).mov")
            if FileManager.default.fileExists(atPath: destination.path()) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedActivityCoverMovie(url: destination)
        }
    }
}
