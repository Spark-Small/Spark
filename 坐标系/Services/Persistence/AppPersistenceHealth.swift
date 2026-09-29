//
//  AppPersistenceHealth.swift
//  坐标系
//
//  SwiftData 生产容器失败时的降级状态 + Gateway 写失败提示
//  （Apple：避免启动 fatalError；错误可理解、可行动）。
//

import Foundation
import Observation

@Observable
@MainActor
final class AppPersistenceHealth {
    /// `true` 表示本会话使用内存库，杀进程后数据不会保留。
    private(set) var isUsingEphemeralStore = false
    private(set) var launchErrorDescription: String?
    /// Gateway 异步落盘失败时的用户可读提示；可点关闭。
    private(set) var writeFailureMessage: String?

    func markEphemeralFallback(error: Error) {
        isUsingEphemeralStore = true
        launchErrorDescription = error.localizedDescription
    }

    func reportWriteFailure(domainKey: String, error: Error) {
        _ = error
        writeFailureMessage = "本地数据保存失败（\(domainKey)），请稍后重试。若频繁出现请清理空间后重启。"
    }

    func dismissWriteFailure() {
        writeFailureMessage = nil
    }
}
