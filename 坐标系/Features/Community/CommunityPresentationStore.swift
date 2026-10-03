//
//  CommunityPresentationStore.swift
//  坐标系
//
//  广场表现态（Compose / toast / pending 复盘预填），与 CommunitySnapshot 分离。
//

import Foundation
import Observation

@MainActor
@Observable
final class CommunityPresentationStore {
    var isComposing = false
    /// 从活动页跳转发复盘时预填正文
    var pendingComposeBody: String?
    var pendingRelatedActivityTitle: String?
    var pendingRelatedActivityID: UUID?
    var toastMessage: String?

    func flash(_ message: String) {
        toastMessage = message
    }

    func beginCompose() {
        isComposing = true
    }

    func endCompose() {
        isComposing = false
    }

    func clearPendingCompose() {
        pendingComposeBody = nil
        pendingRelatedActivityTitle = nil
        pendingRelatedActivityID = nil
    }
}
