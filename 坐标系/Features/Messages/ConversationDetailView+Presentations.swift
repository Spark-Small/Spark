//
//  ConversationDetailView+Presentations.swift
//  坐标系
//
//  会话详情 Sheet / Alert；附件仅图 / 定位 / 活动卡 / @（无转账·贴纸·通话）。
//

import PhotosUI
import SwiftUI
import CoordinateModels

extension ConversationDetailView {
    @ViewBuilder
    func withConversationPresentations(
        _ content: some View,
        conversation: ChatConversation
    ) -> some View {
        content
            .onChange(of: photoPickerItem) { _, item in
                Task { await loadAndSendPhoto(item, conversationID: conversation.id) }
            }
            .sheet(isPresented: $showGroupManage) {
                GroupManageSheet(
                    conversationID: conversationID,
                    onOpenActivity: { activity in
                        selectedActivity = activity
                    },
                    onReport: { showReport = true }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .fullScreenCover(isPresented: Binding(
                get: { activeCallID != nil },
                set: { if !$0 { activeCallID = nil } }
            )) {
                if let activeCallID {
                    CallSessionView(conversationID: conversation.id, callID: activeCallID)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                ActivityMapPickerSheet(
                    locationText: $locationDraft,
                    latitude: $locationLatitude,
                    longitude: $locationLongitude
                )
                .toolbarVisibility(.hidden, for: .tabBar)
                .onDisappear {
                    guard let lat = locationLatitude, let lon = locationLongitude else { return }
                    let name = locationDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    _ = model.sendLocation(
                        name: name.isEmpty ? MessagesCopy.mapLocationFallback : name,
                        latitude: lat,
                        longitude: lon,
                        to: conversation.id
                    )
                    sendPulse += 1
                    locationLatitude = nil
                    locationLongitude = nil
                }
            }
            .alert(
                "\(MessagesCopy.reportTitle)：\(conversation.title)",
                isPresented: $showReport
            ) {
                ForEach(MessagesCopy.reportReasons, id: \.self) { reason in
                    Button(reason, role: .destructive) {
                        app.addModerationTicket(
                            postID: conversation.id,
                            title: conversation.title,
                            reason: reason,
                            targetKind: .conversation
                        )
                        copyFeedback = MessagesCopy.reportSubmitted
                    }
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.reportFooter)
            }
            .alert(
                "退出圈子？",
                isPresented: $confirmLeaveCircle
            ) {
                Button(MessagesCopy.leaveGroup, role: .destructive) {
                    leaveCircleGroupIfPossible()
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text("退出后将离开圈子群聊，成员设置会清除，可随时重新加入。")
            }
            .alert(
                MessagesCopy.clearHistoryTitle,
                isPresented: $confirmClearHistory
            ) {
                Button(MessagesCopy.clearHistoryConfirm, role: .destructive) {
                    model.clearChatHistory(in: conversationID)
                    copyFeedback = MessagesCopy.clearHistoryDone
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.clearHistoryMessage)
            }
            .alert(
                MessagesCopy.leavePeerGroupTitle,
                isPresented: $confirmLeavePeerGroup
            ) {
                Button(MessagesCopy.leaveGroup, role: .destructive) {
                    model.leavePeerGroup(conversationID: conversationID, leaverName: app.user.name)
                    dismiss()
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.leavePeerGroupMessage)
            }
            .alert(
                MessagesCopy.dissolveGroupTitle,
                isPresented: $confirmDissolveGroup
            ) {
                Button(MessagesCopy.dissolveGroup, role: .destructive) {
                    model.dissolveGroup(conversationID: conversationID)
                    dismiss()
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.dissolveGroupMessage)
            }
            .sensoryFeedback(.success, trigger: sendPulse)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: likePulse)
            .platformFeedbackAlert($copyFeedback)
            .alert(
                MessagesCopy.deleteDialogTitle,
                isPresented: Binding(
                    get: { model.conversationPendingDelete?.id == conversationID },
                    set: { if !$0 { model.cancelDelete() } }
                )
            ) {
                Button(MessagesCopy.deleteDialogConfirm, role: .destructive) {
                    model.confirmDelete()
                    dismiss()
                }
                Button(MessagesCopy.deleteDialogCancel, role: .cancel) {
                    model.cancelDelete()
                }
            } message: {
                Text(MessagesCopy.deleteDialogMessage(title: conversation.title))
            }
            .sheet(item: $forwardingMessage) { message in
                MessageForwardPickerSheet(
                    source: message,
                    excludeConversationID: conversationID,
                    onForwarded: { copyFeedback = MessagesCopy.forwardDone }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .alert(
                MessagesCopy.editMessageTitle,
                isPresented: Binding(
                    get: { editingMessage != nil },
                    set: { if !$0 { editingMessage = nil } }
                )
            ) {
                TextField(MessagesCopy.sendPlaceholder, text: $editDraft)
                Button(MessagesCopy.editMessageSave) {
                    guard let editingMessage else { return }
                    if model.editMessage(
                        messageID: editingMessage.id,
                        in: conversationID,
                        newText: editDraft
                    ) {
                        self.editingMessage = nil
                    } else {
                        copyFeedback = MessagesCopy.editMessageUnavailable
                        self.editingMessage = nil
                    }
                }
                Button(MessagesCopy.cancel, role: .cancel) {
                    editingMessage = nil
                }
            }
            .confirmationDialog(
                MessagesCopy.localVoiceTitle,
                isPresented: $confirmLocalVoice,
                titleVisibility: .visible
            ) {
                Button(MessagesCopy.localVoiceSend) {
                    if model.sendVoice(duration: 3, to: conversationID) != nil {
                        sendPulse += 1
                    }
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.localVoiceMessage)
            }
            .sheet(item: $peerProfile) { route in
                NavigationStack {
                    switch route {
                    case .friend(let nickname):
                        // 信息式联系人卡：左关闭、右更多；底栏发消息回到当前会话
                        FriendProfileDetailView(
                            nickname: nickname,
                            messageAction: .dismissToChat
                        )
                        .platformSheetCancellationToolbar(MessagesCopy.close)
                    case .discover(let item):
                        BuddyDetailRouteView(item: item)
                            .platformSheetCancellationToolbar(MessagesCopy.close)
                    }
                }
                .toolbarVisibility(.hidden, for: .tabBar)
                .platformSheet(.browser)
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityBrowserSheet(activity: activity)
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .platformSheet(.browser)
            }
            .sheet(isPresented: Binding(
                get: { selectedPostID != nil },
                set: { if !$0 { selectedPostID = nil } }
            )) {
                if let selectedPostID {
                    NavigationStack {
                        CommunityPostDetailView(postID: selectedPostID)
                            .platformSheetConfirmationToolbar()
                    }
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .platformSheet(.browser)
                }
            }
    }

    @ViewBuilder
    func moreMenu(for conversation: ChatConversation) -> some View {
        ConversationDetailMoreMenu(
            conversation: conversation,
            isOwnedByViewer: conversation.isOwned(by: app.user.name),
            hasBuddyProfile: true,
            hasCircleInfo: circleForConversation(conversation) != nil,
            onTogglePin: { model.togglePin(conversation.id) },
            onToggleMute: { model.toggleMute(conversation.id) },
            onClearHistory: { confirmClearHistory = true },
            onCircleInfo: {
                if let circle = circleForConversation(conversation) {
                    onOpenCircleInfo?(circle)
                }
            },
            onGroupManage: { showGroupManage = true },
            onViewProfile: {
                peerProfile = peerProfileRoute(for: conversation.title)
            },
            onReport: { showReport = true },
            onDissolveGroup: { confirmDissolveGroup = true },
            onLeavePeerGroup: { confirmLeavePeerGroup = true },
            onCancelRegistration: {
                if let activityID = conversation.relatedActivityID {
                    app.cancelActivityRegistration(activityID)
                    dismiss()
                } else {
                    model.requestDelete(conversation)
                }
            },
            onLeaveCircle: { confirmLeaveCircle = true },
            onDeleteConversation: { model.requestDelete(conversation) }
        )
    }

    @ViewBuilder
    func attachMenu(for conversation: ChatConversation) -> some View {
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            Label(MessagesCopy.attachCamera, systemImage: "camera.fill")
        }
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            Label(MessagesCopy.attachPhoto, systemImage: "photo")
        }
        Button(MessagesCopy.attachLocation, systemImage: "mappin.and.ellipse") {
            locationDraft = app.user.city.isEmpty
                ? MessagesCopy.currentLocation
                : app.user.city
            locationLatitude = nil
            locationLongitude = nil
            showLocationPicker = true
        }
        if let activity = relatedActivity(for: conversation)
            ?? activities.inviteableActivities.first {
            Button(MessagesCopy.attachActivity, systemImage: "calendar") {
                _ = model.sendActivityCard(activity, to: conversation.id)
                sendPulse += 1
            }
        }
        if conversation.isGroup {
            Button(MessagesCopy.mentionMembers, systemImage: "at") {
                mentionDraft = ""
            }
        }
    }
}
