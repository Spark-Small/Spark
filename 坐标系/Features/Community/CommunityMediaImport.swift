//
//  CommunityMediaImport.swift
//  坐标系
//
//  PhotosPicker 导入：照片 / 视频写入 CommunityPhotoStore。
//

import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

extension CommunityPhotoStore {
    static let photosAndVideos: PHPickerFilter = .any(of: [.images, .videos])

    /// 从系统相册条目导入照片或视频，返回本地文件名。
    static func savePickerItem(_ item: PhotosPickerItem) async -> String? {
        let isVideo = item.supportedContentTypes.contains {
            $0.conforms(to: UTType.audiovisualContent)
        }
        if isVideo, let movie = try? await item.loadTransferable(type: PickedMovieFile.self) {
            return movie.url.lastPathComponent
        }
        if let data = try? await item.loadTransferable(type: Data.self),
           let name = saveJPEG(data) {
            return name
        }
        if let movie = try? await item.loadTransferable(type: PickedMovieFile.self) {
            return movie.url.lastPathComponent
        }
        return nil
    }
}

private struct PickedMovieFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            Self(url: try CommunityPhotoStore.copyMovie(from: received.file))
        }
    }
}
