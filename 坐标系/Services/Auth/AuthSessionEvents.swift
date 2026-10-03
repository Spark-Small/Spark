//
//  AuthSessionEvents.swift
//  坐标系
//
//  远程会话失效广播：refresh 失败等场景通知 UI 清登录态。
//

import Foundation

enum AuthSessionEvents {
    static let remoteSessionInvalidated = Notification.Name("com.zuobiaoxi.auth.remoteSessionInvalidated")

    static func postRemoteSessionInvalidated() {
        NotificationCenter.default.post(name: remoteSessionInvalidated, object: nil)
    }
}
