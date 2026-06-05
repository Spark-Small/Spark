// Module: SparkCommunity — Network community posts.

import Foundation
import SparkCore
import SparkNetworking

public struct LiveCommunityPostsRepository: CommunityPostsRepository, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchPosts() async throws -> [CommunityPost] {
        do {
            let dto: CommunityPostsResponseDTO = try await apiClient.get(CommunityAPIPath.posts)
            return dto.posts.map(CommunityDTOMapper.post)
        } catch {
            throw CommunityError.underlying(mapToAppError(error))
        }
    }

    public func fetchTabExperience() async throws -> CommunityTabExperience {
        // REASONING: `/v1/community/feed` ships in a follow-up; derive tab from list posts on Live.
        let posts = try await fetchPosts()
        let feedPosts = posts.map { summary in
            CommunityFeedPost(
                id: summary.id,
                authorDisplayName: summary.authorDisplayName,
                authorUserID: summary.id,
                communityName: String(localized: "community.fallback.name", defaultValue: "社区", comment: "Community"),
                content: summary.excerpt,
                likeCount: 0,
                commentCount: summary.replyCount,
                createdAt: Date()
            )
        }
        let items = feedPosts.map { CommunityFeedItem.post($0) }
        return CommunityTabExperience(joinedCommunities: [], feedItems: items, allCommunities: [])
    }

    public func fetchPost(id: String) async throws -> CommunityPostDetail {
        do {
            let dto: CommunityPostDetailResponseDTO = try await apiClient.get(CommunityAPIPath.post(id: id))
            return CommunityDTOMapper.postDetail(from: dto.post)
        } catch {
            throw CommunityError.underlying(mapToAppError(error))
         }
    }

    public func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
        do {
            let body = try JSONEncoder().encode(
                CreateCommunityPostRequestDTO(
                    title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    body: draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            let dto: CreateCommunityPostResponseDTO = try await apiClient.post(
                CommunityAPIPath.posts,
                body: body,
                as: CreateCommunityPostResponseDTO.self
            )
            return CommunityDTOMapper.post(from: dto.post)
        } catch {
            throw CommunityError.underlying(mapToAppError(error))
        }
    }

    public func createReply(postID: String, body: String) async throws -> CommunityPostReply {
        do {
            let payload = try JSONEncoder().encode(
                CreateCommunityReplyRequestDTO(body: body.trimmingCharacters(in: .whitespacesAndNewlines))
            )
            let dto: CreateCommunityReplyResponseDTO = try await apiClient.post(
                CommunityAPIPath.replies(postID: postID),
                body: payload,
                as: CreateCommunityReplyResponseDTO.self
            )
            return CommunityDTOMapper.reply(from: dto.reply)
        } catch {
            throw CommunityError.underlying(mapToAppError(error))
        }
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let communityError = error as? CommunityError,
           case let .underlying(appError) = communityError {
            return appError
        }
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(message: error.localizedDescription)
    }
}
