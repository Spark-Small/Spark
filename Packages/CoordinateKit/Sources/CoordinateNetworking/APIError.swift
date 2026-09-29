//
//  APIError.swift
//  CoordinateNetworking
//

import Foundation

public enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case transport(String)
    case offline
    /// Backend business envelope `code != 0`.
    case business(code: Int, message: String)

    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            "无效的请求地址"
        case .invalidResponse:
            "服务器响应无效"
        case .httpStatus(let code):
            "请求失败（\(code)）"
        case .decodingFailed:
            "数据解析失败"
        case .transport(let message):
            message
        case .offline:
            "当前无网络连接，请稍后再试"
        case .business(_, let message):
            message.isEmpty ? "业务请求失败" : message
        }
    }
}
