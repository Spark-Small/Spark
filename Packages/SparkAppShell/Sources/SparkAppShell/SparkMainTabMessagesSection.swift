// Module: SparkAppShell — Messages tab with unread badge.

import SparkMessages
import SwiftUI

struct SparkMainTabMessagesSection: View {
    let peerDisplayNameStore: PeerDisplayNameStore
    let messagesViewModel: MessagesViewModel
    @Binding var pendingConversationThreadID: String?
    let onOpenActivity: (String) -> Void
    let onProposeMeetup: (String) -> Void
    let onOpenActivityTab: () -> Void
    let onScannedPayload: (String) -> Void

    var body: some View {
        MessagesRootView(
            viewModel: messagesViewModel,
            pendingConversationThreadID: $pendingConversationThreadID,
            onOpenActivity: onOpenActivity,
            onProposeMeetup: onProposeMeetup,
            onOpenActivityTab: onOpenActivityTab,
            onScannedPayload: onScannedPayload
        )
        .environment(peerDisplayNameStore)
    }
}
