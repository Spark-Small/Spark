//
//  LoginAuthWorkGate.swift
//  坐标系
//
//  登录 / 创建账号共用 busy + 代际取消语义。
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginAuthWorkGate {
    enum Kind {
        case sendingCode
        case submitting
        case social
    }

    private(set) var isSendingCode = false
    private(set) var isSubmitting = false
    private(set) var isSocialBusy = false

    private var workTask: Task<Void, Never>?
    private var workGeneration = 0

    var isBusy: Bool { isSendingCode || isSubmitting || isSocialBusy }

    /// 启动一类工作；取消进行中的任务，返回本代 generation。
    @discardableResult
    func begin(_ kind: Kind) -> Int {
        workTask?.cancel()
        workGeneration += 1
        isSendingCode = false
        isSubmitting = false
        isSocialBusy = false
        switch kind {
        case .sendingCode: isSendingCode = true
        case .submitting: isSubmitting = true
        case .social: isSocialBusy = true
        }
        return workGeneration
    }

    func finish(_ generation: Int, clearing kind: Kind) {
        guard generation == workGeneration else { return }
        switch kind {
        case .sendingCode: isSendingCode = false
        case .submitting: isSubmitting = false
        case .social: isSocialBusy = false
        }
    }

    /// 在指定 busy 种类下跑异步工作；自动 finish / 代际保护。
    func run(_ kind: Kind, _ work: @escaping @MainActor (_ generation: Int) async -> Void) {
        let generation = begin(kind)
        workTask = Task { @MainActor in
            defer { finish(generation, clearing: kind) }
            await work(generation)
        }
    }

    func isCurrent(_ generation: Int) -> Bool {
        generation == workGeneration && !Task.isCancelled
    }

    func cancel() {
        workTask?.cancel()
        workTask = nil
        isSendingCode = false
        isSubmitting = false
        isSocialBusy = false
        workGeneration += 1
    }
}
