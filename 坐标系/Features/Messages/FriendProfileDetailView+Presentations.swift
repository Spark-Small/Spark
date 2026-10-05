//
//  FriendProfileDetailView+Presentations.swift
//  坐标系
//
//  通讯录资料卡：聊天 Sheet / 分组 / 举报拉黑删除。
//

import SwiftUI
import CoordinateModels

extension FriendProfileDetailView {
    @ViewBuilder
    func applyingFriendProfilePresentations<Content: View>(_ content: Content) -> some View {
        content
            .sheet(item: $chatSheet) { route in
                NavigationStack {
                    ConversationDetailView(
                        conversationID: route.conversationID,
                        chatContext: route.chatContext
                    )
                }
                .independentNavigationSheetChrome()
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showGroupPicker) {
                FriendGroupPickerSheet(nickname: nickname)
            }
            .alert(
                "\(MessagesCopy.reportTitle)：\(nickname)",
                isPresented: $showReport
            ) {
                ForEach(MessagesCopy.reportReasons, id: \.self) { reason in
                    Button(reason, role: .destructive) {
                        app.addModerationTicket(
                            postID: UUID(),
                            title: nickname,
                            reason: reason,
                            targetKind: .person
                        )
                        feedback = MessagesCopy.reportSubmitted
                    }
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.reportFooter)
            }
            .alert(
                MessagesCopy.friendBlockConfirmTitle,
                isPresented: $confirmBlock
            ) {
                Button(MessagesCopy.friendAddToBlacklist, role: .destructive) {
                    app.blockUser(nickname)
                    feedback = MessagesCopy.friendBlocked
                    dismiss()
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.friendBlockConfirmMessage)
            }
            .confirmationDialog(
                MessagesCopy.friendDeleteConfirmTitle,
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button(MessagesCopy.friendDelete, role: .destructive) {
                    model.deleteFriend(named: nickname)
                    dismiss()
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.friendDeleteConfirmMessage)
            }
            .platformFeedbackAlert($feedback)
    }
}
