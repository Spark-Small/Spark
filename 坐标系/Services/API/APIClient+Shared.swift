//
//  APIClient+Shared.swift
//  坐标系
//

import CoordinateNetworking
import Foundation
import CoordinateModels

extension APIClient {
    /// Shared client: ISO/envelope decoder + Keychain JWT + 401 refresh。
    /// Computed so DEBUG `baseURLOverride` 立刻生效。
    static var shared: APIClient {
        APIClient(
            baseURL: APIConfiguration.baseURL,
            tokenProvider: StoredAPITokenProvider(),
            tokenRefresher: AuthTokenRefresher(),
            decoder: APIJSONCoding.makeDecoder()
        )
    }
}
