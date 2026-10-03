//
//  ActivitiesPresentationStore.swift
//  坐标系
//
//  活动域表现态（Sheet / toast），与目录 / 报名快照分离。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class ActivitiesPresentationStore {
    var isComposing = false
    var editingActivityID: Activity.ID?
    var joinSuccessActivityID: Activity.ID?
    var publishSuccessActivityID: Activity.ID?
    var toastMessage: String?
    var lightFeedbackMessage: String?

    func flash(_ message: String) {
        toastMessage = message
    }

    func flashLight(_ message: String) {
        lightFeedbackMessage = message
    }

    func beginCompose(editing id: Activity.ID? = nil) {
        editingActivityID = id
        isComposing = true
    }

    func endCompose() {
        isComposing = false
        editingActivityID = nil
    }

    func dismissJoinSuccess() {
        joinSuccessActivityID = nil
    }

    func dismissPublishSuccess() {
        publishSuccessActivityID = nil
    }
}
