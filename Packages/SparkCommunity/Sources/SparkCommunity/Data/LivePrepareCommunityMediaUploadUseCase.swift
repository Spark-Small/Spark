// Module: SparkCommunity — Live media staging before post publish (MODULE-E).

import CryptoKit
import Foundation
import SparkCore
import SparkNetworking

public struct LivePrepareCommunityMediaUploadUseCase: Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func uploadImage(_ imageData: Data) async throws -> URL {
        let digest = sha256Hex(imageData)
        let body = try JSONEncoder().encode(
            StageCommunityMediaRequestDTO(
                kind: SparkGalleryMediaKind.image.rawValue,
                contentSHA256: digest,
                contentType: "image/jpeg"
            )
        )
        let dto: StageCommunityMediaResponseDTO = try await apiClient.post(
            CommunityAPIPath.mediaStage,
            body: body,
            as: StageCommunityMediaResponseDTO.self
        )
        guard let url = URL(string: dto.url) else {
            throw CommunityError.underlying(.unknown(message: "Invalid staged media URL"))
        }
        return url
    }

    public func uploadVideo(from fileURL: URL) async throws -> SparkGalleryMedia {
        let digest = sha256Hex(Data(fileURL.path().utf8))
        let body = try JSONEncoder().encode(
            StageCommunityMediaRequestDTO(
                kind: SparkGalleryMediaKind.video.rawValue,
                contentSHA256: digest,
                contentType: "video/quicktime"
            )
        )
        let dto: StageCommunityMediaResponseDTO = try await apiClient.post(
            CommunityAPIPath.mediaStage,
            body: body,
            as: StageCommunityMediaResponseDTO.self
        )
        guard let url = URL(string: dto.url) else {
            throw CommunityError.underlying(.unknown(message: "Invalid staged video URL"))
        }
        return SparkGalleryMedia(
            id: dto.id,
            url: url,
            kind: .video,
            posterURL: dto.posterURL.flatMap(URL.init(string:))
        )
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

extension LivePrepareCommunityMediaUploadUseCase: PrepareCommunityMediaUploadUseCaseProtocol {}
