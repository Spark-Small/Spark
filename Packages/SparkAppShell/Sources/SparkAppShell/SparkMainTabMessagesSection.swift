// Module: SparkAppShell — Messages tab with unread badge.

import SparkMessages
import SwiftUI

struct SparkMainTabMessagesSection: View {
    let messagesViewModel: MessagesViewModel?
    @Binding var pendingConversationThreadID: String?
    let onOpenActivity: (String) -> Void
    let onOpenLikes: () -> Void
    let ensureMessagesViewModel: () -> Void

    var body: some View {
        if let messagesViewModel {
            MessagesRootView(
                viewModel: messagesViewModel,
                pendingConversationThreadID: $pendingConversationThreadID,
                onOpenActivity: onOpenActivity,
                onOpenLikes: onOpenLikes
            )
        } else {
            ProgressView()
                .task { ensureMessagesViewModel() }
        }
    }
}
