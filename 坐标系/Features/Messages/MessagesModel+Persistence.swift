//
//  MessagesModel+Persistence.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

extension MessagesModel {
    func index(of id: ChatConversation.ID) -> Int? {
        conversations.firstIndex { $0.id == id }
    }

    func bootstrapGroupMembersIfNeeded() {
        for conversation in conversations where conversation.isGroup {
            if groupMembersByConversation[conversation.id]?.isEmpty != false {
                groupMembersByConversation[conversation.id] = groupAdminService.bootstrapMembers(
                    ownerName: conversation.ownerName,
                    memberNames: conversation.memberNames
                )
            }
        }
    }

    func storeBootstrapMembers(for conversation: ChatConversation) {
        guard conversation.isGroup else { return }
        groupMembersByConversation[conversation.id] = groupAdminService.bootstrapMembers(
            ownerName: conversation.ownerName,
            memberNames: conversation.memberNames
        )
    }

    func normalizeMessageRequests() {
        for index in conversations.indices where conversations[index].isMessageRequest {
            if conversations[index].requestSource == nil {
                conversations[index].requestSource = .directMessage
            }
            if conversations[index].requestPreviewText?.isEmpty != false {
                conversations[index].requestPreviewText = conversations[index].inboxPreview
            }
        }
    }

    /// 用线程最后一条对齐收件箱预览；并把旧「私聊/活动群」副标题归一为好友/群聊
    func reconcileInboxPreviews() {
        var changed = false
        for index in conversations.indices {
            let id = conversations[index].id
            if let last = threads[id]?.last {
                let preview = last.previewText
                if conversations[index].lastMessage != preview {
                    conversations[index].lastMessage = preview
                    changed = true
                }
                if conversations[index].lastMessageIsMe != last.isMe {
                    conversations[index].lastMessageIsMe = last.isMe
                    changed = true
                }
                if conversations[index].updatedAt != last.sentAt {
                    conversations[index].updatedAt = last.sentAt
                    changed = true
                }
            }

            switch conversations[index].kind {
            case .direct:
                if conversations[index].subtitle != MessagesCopy.friendSubtitle {
                    conversations[index].subtitle = MessagesCopy.friendSubtitle
                    changed = true
                }
            case .activity, .group:
                if conversations[index].kind == .activity {
                    let expected = MessagesCopy.activityGroupSubtitleLine(
                        eventAt: conversations[index].eventAt
                    )
                    if conversations[index].subtitle != expected {
                        conversations[index].subtitle = expected
                        changed = true
                    }
                } else if conversations[index].subtitle != MessagesCopy.groupSubtitle {
                    conversations[index].subtitle = MessagesCopy.groupSubtitle
                    changed = true
                }
                if conversations[index].kind == .activity, conversations[index].memberNames.isEmpty {
                    var members = conversations[index].ownerName.map { [$0] } ?? []
                    if !members.contains(where: { $0 == "林屿" || $0 == "我" }) {
                        members.append("林屿")
                    }
                    conversations[index].memberNames = members
                    changed = true
                }
            case .circle:
                let memberCount = max(conversations[index].memberNames.count, 1)
                let expected = MessagesCopy.circleGroupSubtitleLine(memberCount: memberCount)
                if conversations[index].subtitle != expected {
                    conversations[index].subtitle = expected
                    changed = true
                }
            case .notice:
                if conversations[index].subtitle != MessagesCopy.noticeSubtitle {
                    conversations[index].subtitle = MessagesCopy.noticeSubtitle
                    changed = true
                }
            }
        }
        if changed { persist() }
    }

    func reloadFromRepository() async {
        guard let snapshot = try? await repository.loadAsync() else { return }
        persistenceGeneration = repository.currentPersistenceGeneration()
        conversations = snapshot.conversations
        friendRequests = snapshot.friendRequests
        friendRemarks = snapshot.friendRemarks
        friendGroups = snapshot.friendGroups
        groupMembersByConversation = Dictionary(
            uniqueKeysWithValues: snapshot.groupMembers.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
        transferRecords = snapshot.transferRecords
        callRecords = snapshot.callRecords
        threads = Dictionary(
            uniqueKeysWithValues: snapshot.threads.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
        bootstrapGroupMembersIfNeeded()
        normalizeMessageRequests()
        reconcileInboxPreviews()
        refreshTransferExpirations()
    }

    func discardPendingPersistence() async {
        for task in autoReplyTasks.values {
            task.cancel()
        }
        autoReplyTasks.removeAll()
        for task in readReceiptTasks.values {
            task.cancel()
        }
        readReceiptTasks.removeAll()
        for task in transferExpirationTasks.values {
            task.cancel()
        }
        transferExpirationTasks.removeAll()
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    func persist() {
        let snapshot = MessagesSnapshot(
            conversations: conversations,
            threads: Dictionary(
                uniqueKeysWithValues: threads.map { ($0.key.uuidString, $0.value) }
            ),
            friendRequests: friendRequests,
            outgoingFriendRequests: outgoingFriendRequests,
            friendRemarks: friendRemarks,
            friendGroups: friendGroups,
            groupMembers: Dictionary(
                uniqueKeysWithValues: groupMembersByConversation.map { ($0.key.uuidString, $0.value) }
            ),
            transferRecords: transferRecords,
            callRecords: callRecords
        )
        let previousTask = persistTask
        let generation = persistenceGeneration
        persistTask = MainActorPersistence.chained(after: previousTask) {
            do {
                try await self.repository.replaceAsync(with: snapshot, generation: generation)
            } catch {
                assertionFailure("Messages persist failed: \(error)")
                PersistenceWriteFailureReporter.record(domainKey: "messages", error: error)
            }
        }
    }
}
