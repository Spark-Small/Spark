// Module: SparkCommunity — Mock media upload before post publish (MODULE-E).

import CryptoKit
import Foundation
import SparkCore

public protocol PrepareCommunityMediaUploadUseCaseProtocol: Sendable {
    func uploadImage(_ imageData: Data) async throws -> URL
    func uploadVideo(from fileURL: URL) async throws -> SparkGalleryMedia
}

public struct PrepareCommunityMediaUploadUseCase: Sendable {
    public init() {}
    private static let mockVideoURL = URL(
        string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
    )!

    public func uploadImage(_ imageData: Data) async throws -> URL {
        let digest = SHA256.hash(data: imageData)
        let seed = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        guard let url = URL(string: "https://picsum.photos/seed/community-\(seed)/800/450") else {
            throw CommunityError.underlying(.unknown(message: "Invalid media URL"))
        }
        return url
    }

    public func uploadVideo(from fileURL: URL) async throws -> SparkGalleryMedia {
        let digest = SHA256.hash(data: Data(fileURL.path().utf8))
        let seed = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        let poster = URL(string: "https://picsum.photos/seed/community-video-\(seed)/800/450")
        return SparkGalleryMedia(
            id: "video-\(seed)",
            url: Self.mockVideoURL,
            kind: .video,
            posterURL: poster
        )
    }

    public func callAsFunction(_ imageData: Data) async throws -> URL {
        try await uploadImage(imageData)
    }
}

extension PrepareCommunityMediaUploadUseCase: PrepareCommunityMediaUploadUseCaseProtocol {}
