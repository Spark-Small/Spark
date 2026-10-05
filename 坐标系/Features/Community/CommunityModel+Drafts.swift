//
//  CommunityModel+Drafts.swift
//  坐标系
//
//  发帖草稿箱：本机列表读写，经 presentation 打开 Compose。
//

import Foundation

extension CommunityModel {
    /// 本机发帖草稿（按更新时间倒序）；UI 读此缓存，写后 `reloadPostDrafts()`。
    var postDrafts: [CommunityPostDraft] {
        get { presentation.postDrafts }
        set { presentation.postDrafts = newValue }
    }

    var editingDraftID: UUID? {
        get { presentation.editingDraftID }
        set { presentation.editingDraftID = newValue }
    }

    func reloadPostDrafts() {
        presentation.postDrafts = CommunityPostDraftStore.loadAll()
    }

    func postDraft(id: UUID) -> CommunityPostDraft? {
        CommunityPostDraftStore.draft(id: id) ?? postDrafts.first { $0.id == id }
    }

    @discardableResult
    func savePostDraft(
        id: UUID?,
        body: String,
        tags: [String],
        localPhotoNames: [String],
        relatedActivityID: UUID?,
        relatedActivityTitle: String?
    ) -> CommunityPostDraft? {
        let draftID = id ?? UUID()
        let existing = CommunityPostDraftStore.draft(id: draftID)
        let draft = CommunityPostDraft(
            id: draftID,
            body: body,
            tags: tags,
            localPhotoNames: localPhotoNames,
            relatedActivityID: relatedActivityID,
            relatedActivityTitle: relatedActivityTitle,
            createdAt: existing?.createdAt ?? .now,
            updatedAt: .now
        )
        guard draft.hasContent else { return nil }
        CommunityPostDraftStore.upsert(draft)
        reloadPostDrafts()
        return draft
    }

    func deletePostDraft(id: UUID, deleteMedia: Bool = true) {
        CommunityPostDraftStore.delete(id: id, deleteMedia: deleteMedia)
        if editingDraftID == id {
            editingDraftID = nil
        }
        reloadPostDrafts()
    }

    func beginCompose(draftID: UUID? = nil) {
        presentation.beginCompose(draftID: draftID)
    }
}
