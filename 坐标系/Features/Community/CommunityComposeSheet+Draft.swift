//
//  CommunityComposeSheet+Draft.swift
//  坐标系
//
//  发帖：草稿箱落盘；取消确认；scenePhase 后台静默自动存。
//

import CoordinateModels
import SwiftUI
import UIKit

extension CommunityComposeSheet {
    var hasDraftableContent: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !savedPhotoNames.isEmpty
            || !parsedTags.isEmpty
            || relatedActivityID != nil
    }

    var canSaveDraft: Bool {
        hasDraftableContent && !isPreparingPhotos
    }

    func attemptCancelCompose() {
        if hasDraftableContent {
            showDraftDismissDialog = true
        } else {
            dismissComposeWithoutSaving()
        }
    }

    /// - Parameters:
    ///   - dismissAfter: 存完是否关闭发帖 Sheet
    ///   - announce: 是否轻反馈「已存入草稿箱」（后台自动存为静默）
    @discardableResult
    func saveCurrentDraft(dismissAfter: Bool, announce: Bool = true) -> Bool {
        let matched = linkableActivities.first { $0.id == relatedActivityID }
        guard let draft = model.savePostDraft(
            id: model.editingDraftID,
            body: bodyText,
            tags: parsedTags,
            localPhotoNames: savedPhotoNames,
            relatedActivityID: matched?.id ?? relatedActivityID,
            relatedActivityTitle: matched?.title
        ) else { return false }
        model.editingDraftID = draft.id
        if announce {
            draftFeedback = CommunityComposeCopy.draftSavedFeedback
        }
        if dismissAfter {
            suppressDraftAutosave = true
            model.presentation.endCompose()
            dismiss()
        }
        return true
    }

    /// App 进后台 / 失活：有内容则静默写入草稿箱（防意外退出丢失）。
    func autosaveDraftForScenePhaseIfNeeded() {
        guard !suppressDraftAutosave, canSaveDraft else { return }
        _ = saveCurrentDraft(dismissAfter: false, announce: false)
    }

    func discardComposeAndDismiss() {
        suppressDraftAutosave = true
        // 「不保存」= 不要这份内容：有草稿条目则整份删除；否则只清会话新媒体。
        if let draftID = model.editingDraftID {
            model.deletePostDraft(id: draftID, deleteMedia: true)
        } else {
            for name in savedPhotoNames {
                LocalMediaLibrary.delete(named: name)
            }
        }
        dismissComposeWithoutSaving()
    }

    func dismissComposeWithoutSaving() {
        suppressDraftAutosave = true
        model.presentation.endCompose()
        dismiss()
    }

    @MainActor
    func applyDraftIfNeeded() async {
        guard let draftID = model.editingDraftID,
              let draft = model.postDraft(id: draftID)
        else { return }
        bodyText = draft.body
        tagText = draft.tags.joined(separator: " ")
        relatedActivityID = draft.relatedActivityID
        savedPhotoNames = draft.localPhotoNames
        previewImages = await CommunityPostDraftMedia.previewImages(for: draft.localPhotoNames)
        pickerItems = []
    }
}
