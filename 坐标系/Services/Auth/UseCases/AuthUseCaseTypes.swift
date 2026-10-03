//
//  AuthUseCaseTypes.swift
//  坐标系
//
//  登录 UseCase 结果类型（与 UI / Session 解耦）。
//

import Foundation

/// 短信 / OAuth 登录成功后要写入会话的快照。
struct AuthSignInSuccess: Equatable, Sendable {
    let snapshot: AuthSessionSnapshot
    let userIDPrefix: String?
}

enum AuthSignInFailure: Equatable, Sendable {
    case message(String)
    case canceled
}

enum AuthSignInResult: Equatable, Sendable {
    case success(AuthSignInSuccess)
    case failure(AuthSignInFailure)

    var errorMessage: String? {
        switch self {
        case .success: nil
        case .failure(.canceled): nil
        case .failure(.message(let message)): message
        }
    }
}

enum AuthSendCodeResult: Equatable, Sendable {
    case success
    case failure(String)
}
