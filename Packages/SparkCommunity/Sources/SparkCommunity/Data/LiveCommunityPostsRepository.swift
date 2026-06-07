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
        let dto: CommunityPostsResponseDTO = try await get(CommunityAPIPath.posts)
        return dto.posts.map(CommunityDTOMapper.post)
    }

    public func fetchTabExperience() async throws -> CommunityTabExperience {
        do {
            let dto: CommunityTabFeedResponseDTO = try await get(CommunityAPIPath.feed)
            return CommunityDTOMapper.tabExperience(from: dto)
        } catch let error as CommunityError {
            // REASONING: Staging may lag feed rollout; derive minimal tab from posts list on 404 only.
            if case let .underlying(.server(code, _)) = error, code == 404 {
                return try await derivedTabExperience()
            }
            throw error
        }
    }

    public func fetchCommunityDetail(id: String) async throws -> CommunityDetail {
        let dto: CommunityDetailResponseDTO = try await get(CommunityAPIPath.community(id: id))
        return CommunityDTOMapper.communityDetail(from: dto.community)
    }

    public func fetchCommunityActivities(communityID: String) async throws -> [CommunityLinkedActivity] {
        let dto: CommunityActivitiesResponseDTO = try await get(
            CommunityAPIPath.communityActivities(id: communityID)
        )
        return dto.activities.map(CommunityDTOMapper.linkedActivity)
    }

    public func fetchCommunityMembers(communityID: String) async throws -> [CommunityMember] {
        let dto: CommunityMembersResponseDTO = try await get(
            CommunityAPIPath.communityMembers(id: communityID)
        )
        return dto.members.map(CommunityDTOMapper.member)
    }

    public func fetchCommunityPosts(communityID: String) async throws -> [CommunityFeedPost] {
        let dto: CommunityTabFeedResponseDTO = try await get(CommunityAPIPath.feed)
        let experience = CommunityDTOMapper.tabExperience(from: dto)
        guard let communityName = experience.allCommunities.first(where: { $0.id == communityID })?.name
            ?? experience.joinedCommunities.first(where: { $0.id == communityID })?.name
        else { return [] }

        return experience.feedItems.compactMap { item in
            guard case .post(let post) = item, post.communityName == communityName else { return nil }
            return post
        }
    }

    public func fetchPost(id: String) async throws -> CommunityPostDetail {
        let dto: CommunityPostDetailResponseDTO = try await get(CommunityAPIPath.post(id: id))
        return CommunityDTOMapper.postDetail(from: dto.post)
    }

    public func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
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
    }

    public func createReply(postID: String, body: String) async throws -> CommunityPostReply {
        let payload = try JSONEncoder().encode(
            CreateCommunityReplyRequestDTO(body: body.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        let dto: CreateCommunityReplyResponseDTO = try await apiClient.post(
            CommunityAPIPath.replies(postID: postID),
            body: payload,
            as: CreateCommunityReplyResponseDTO.self
        )
        return CommunityDTOMapper.reply(from: dto.reply)
    }

    public func createRecapPost(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail {
        try CommunityRecapDraft.validate(draft)
        let body = try JSONEncoder().encode(
            CreateCommunityRecapRequestDTO(
                title: draft.postTitle,
                body: draft.normalizedBody,
                kind: CommunityPostKind.activityRecap.rawValue,
                activityID: draft.activityID
            )
        )
        let dto: CommunityPostDetailResponseDTO = try await apiClient.post(
            CommunityAPIPath.posts,
            body: body,
            as: CommunityPostDetailResponseDTO.self
        )
        return CommunityDTOMapper.postDetail(from: dto.post)
    }

    private func derivedTabExperience() async throws -> CommunityTabExperience {
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
        return CommunityTabExperience(
            joinedCommunities: [],
            feedItems: feedPosts.map { .post($0) },
            allCommunities: []
        )
    }

    private func get<T: Decodable & Sendable>(_ path: String) async throws -> T {
        do {
            return try await apiClient.get(path)
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
