// Module: SparkActivity — Stage activity cover before publish (Mock until Live upload ships).

import CryptoKit
import Foundation
import SparkCore

public struct ActivityUploadedCover: Sendable, Equatable {
    public let url: URL
    public let posterURL: URL?
    public let isVideo: Bool

    public init(url: URL, posterURL: URL? = nil, isVideo: Bool = false) {
        self.url = url
        self.posterURL = posterURL
        self.isVideo = isVideo
    }
}

public protocol PrepareActivityCoverUploadUseCaseProtocol: Sendable {
    func uploadImage(_ imageData: Data) async throws -> ActivityUploadedCover
    func uploadVideo(from fileURL: URL) async throws -> ActivityUploadedCover
}

public struct PrepareActivityCoverUploadUseCase: Sendable {
    private static let mockVideoURL = URL(
        string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
    )!

    public init() {}

    public func uploadImage(_ imageData: Data) async throws -> ActivityUploadedCover {
        let digest = SHA256.hash(data: imageData)
        let seed = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        guard let url = URL(string: "https://picsum.photos/seed/activity-cover-\(seed)/800/450") else {
            throw ActivityError.underlying(.unknown(message: "Invalid cover URL"))
        }
        return ActivityUploadedCover(url: url, isVideo: false)
    }

    public func uploadVideo(from fileURL: URL) async throws -> ActivityUploadedCover {
        let digest = SHA256.hash(data: Data(fileURL.path().utf8))
        let seed = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        let poster = URL(string: "https://picsum.photos/seed/activity-video-\(seed)/800/450")
        return ActivityUploadedCover(url: Self.mockVideoURL, posterURL: poster, isVideo: true)
    }
}

extension PrepareActivityCoverUploadUseCase: PrepareActivityCoverUploadUseCaseProtocol {}
