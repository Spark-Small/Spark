//
//  ConversationDetailView+Actions.swift
//  坐标系
//
//  会话详情动作：发送、选图、退群、关联查询（共享 @State）。
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

extension ConversationDetailView {
    func send(to id: ChatConversation.ID) {
        guard !isOutboundBlocked else { return }
        switch ContentModeration.scanText(draft) {
        case .allow:
            break
        case .block(let reason):
            copyFeedback = reason
            return
        }
        guard model.send(text: draft, to: id, replyingTo: replyTo) != nil else { return }
        draft = ""
        replyTo = nil
        sendPulse += 1
    }

    func openLink(_ urlString: String) {
        if let postID = Self.communityPostID(from: urlString) {
            selectedPostID = postID
            return
        }
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    static func communityPostID(from urlString: String) -> UUID? {
        guard let url = URL(string: urlString),
              url.scheme == "zuobiaoxi",
              url.host == "community"
        else { return nil }
        let idString = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return UUID(uuidString: idString)
    }

    func circleForConversation(_ conversation: ChatConversation) -> InterestCircle? {
        guard let circleID = conversation.relatedCircleID else { return nil }
        return buddies.circle(id: circleID)
    }

    func leaveCircleGroupIfPossible() {
        guard let conversation else {
            dismiss()
            return
        }
        if let circleID = conversation.relatedCircleID,
           let circle = buddies.circle(id: circleID) {
            model.leaveCircleChat(circleID: circleID, leaverName: app.user.name)
            buddies.leaveCircle(circle)
            dismiss()
        } else {
            model.requestDelete(conversation)
        }
    }

    /// 仅退出活动群聊；报名 / 行程仍在「我的活动」。
    func leaveActivityGroupIfPossible() {
        guard let conversation else {
            dismiss()
            return
        }
        if let activityID = conversation.relatedActivityID {
            model.leaveGroupChat(
                activityID: activityID,
                leaverName: app.user.name,
                currentUserIsOwner: conversation.isOwned(by: app.user.name)
            )
            dismiss()
        } else {
            model.requestDelete(conversation)
        }
    }

    func loadAndSendPhoto(_ item: PhotosPickerItem?, conversationID: ChatConversation.ID) async {
        guard let item else { return }
        defer { photoPickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              UIImage(data: data) != nil
        else {
            copyFeedback = MessagesCopy.photoImportFailed
            return
        }
        let decision = await MediaModerationService.moderateImageData(
            data,
            context: .chat,
            actorKey: app.user.name
        )
        if case .block(let reason) = decision {
            copyFeedback = reason
            return
        }
        guard model.sendImageJPEG(data, to: conversationID) != nil else {
            copyFeedback = MessagesCopy.photoImportFailed
            return
        }
        sendPulse += 1
    }

    func relatedActivity(for conversation: ChatConversation) -> Activity? {
        if let id = conversation.relatedActivityID {
            return activities.activity(id: id)
        }
        return activities.activity(matchingTitle: conversation.title)
    }

    func toolbarTapAction(for conversation: ChatConversation) -> (() -> Void)? {
        switch conversation.kind {
        case .direct:
            return { peerProfile = peerProfileRoute(for: conversation.title) }
        case .circle:
            return {
                if let circle = circleForConversation(conversation) {
                    onOpenCircleInfo?(circle)
                } else {
                    showGroupManage = true
                }
            }
        case .activity, .group, .notice:
            return conversation.isGroup ? { showGroupManage = true } : nil
        }
    }

    /// 已是好友 → 通讯录资料卡；否则有发现卡走发现详情，再否则仍给轻量好友资料壳。
    func peerProfileRoute(for nickname: String) -> ConversationPeerProfileRoute? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        if model.isDirectFriend(with: name) {
            return .friend(nickname: name)
        }
        if let item = buddies.item(for: name) {
            return .discover(item)
        }
        return .friend(nickname: name)
    }

    func handleThreadAppear(conversation: ChatConversation) {
        model.activeConversationID = conversationID
        model.markRead(conversationID)
        pendingScrollMessageID = focusMessageID
        if conversation.kind != .notice, messages.isEmpty {
            isComposerFocused = true
        }
        if conversation.kind == .activity,
           let activity = relatedActivity(for: conversation) {
            app.handle(.activityUpdated(activity.id))
        }
        if activeCallID == nil, let pendingCallID {
            activeCallID = pendingCallID
            app.pendingCallID = nil
        }
        model.refreshTransferExpirations()
    }

    func handleThreadDisappear() {
        if model.activeConversationID == conversationID {
            model.activeConversationID = nil
        }
    }

    /// 私聊「请对方形象认证」：自己须已认证；向会话发送请求文案（不假服务端确认）。
    func askPeerPhotoVerification(in conversation: ChatConversation) {
        guard conversation.kind == .direct else { return }
        let selfOK = photoVerification.isVerified(for: app.user)
        let peerItem = buddies.item(for: conversation.title)
        let peerFlags = TrustPublicCredentials.flags(
            nickname: conversation.title,
            currentUserName: app.user.name,
            buddyItem: peerItem,
            membershipActive: false,
            liveHostedCount: activities.activities.filter {
                $0.hostName.caseInsensitiveCompare(conversation.title) == .orderedSame
            }.count
        )
        switch ProfilePhotoVerificationRequest.canRequest(
            selfVerified: selfOK,
            peerVerified: peerFlags.photoVerified
        ) {
        case .needSelfVerified:
            copyFeedback = ProfilePhotoVerificationRequest.needSelfVerifiedMessage
        case .peerAlreadyVerified:
            copyFeedback = ProfilePhotoVerificationRequest.peerAlreadyVerifiedMessage
        case .allowed:
            guard model.send(
                text: ProfilePhotoVerificationRequest.chatMessage,
                to: conversation.id
            ) != nil else { return }
            sendPulse += 1
            copyFeedback = ProfilePhotoVerificationRequest.sentFeedback
        }
    }
}
