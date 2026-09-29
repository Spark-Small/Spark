//
//  APIEndpoint+Moderation.swift
//  坐标系
//
//  内容安全 / 形象联网复核（Private Detector 与身份二次确认）。
//

import CoordinateNetworking
import Foundation

extension APIEndpoint where Response == MediaModerationResponse {
    static func moderateMedia(_ body: MediaModerationRequest) throws -> APIEndpoint<MediaModerationResponse> {
        APIEndpoint(
            path: "moderation/media",
            method: .post,
            body: try JSONEncoder().encode(body)
        )
    }
}

extension APIEndpoint where Response == IdentityReverifyResponse {
    static func reverifyIdentity(_ body: IdentityReverifyRequest) throws -> APIEndpoint<IdentityReverifyResponse> {
        APIEndpoint(
            path: "identity/reverify",
            method: .post,
            body: try JSONEncoder().encode(body)
        )
    }
}
