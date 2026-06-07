// Module: SparkMessages — Start new DM from inbox actions.

import SwiftUI

extension MessagesRootView {
    var newChatPickerSheet: some View {
        MessagesNewChatPickerView(
            candidates: viewModel.newChatCandidates(),
            onSelect: { candidate in
                Task { await openDirectMessage(candidate: candidate) }
            }
        )
        .environment(peerDisplayNameStore)
    }

    @MainActor
    func openDirectMessage(candidate: MessagesChatCandidate) async {
        let displayName = peerDisplayNameStore.resolvedDisplayName(
            userID: candidate.id,
            fallback: candidate.displayName
        )
        do {
            let threadID = try await viewModel.ensureDirectMessageThread(
                peerUserID: candidate.id,
                peerDisplayName: displayName
            )
            if let match = viewModel.unmessagedMatches.first(where: { $0.user.id == candidate.id }) {
                viewModel.graduateMatch(match, to: threadID)
            }
            await viewModel.load()
            showNewChatPicker = false
            selectedInboxSegment = .dm
            if let thread = viewModel.thread(for: threadID) {
                openThread(thread)
            }
        } catch {
            Self.logger.error(
                "ensureDirectMessageThread failed: \(error.localizedDescription, privacy: .public)"
            )
            matchOpenErrorMessage = (error as? MessagesError)?.errorDescription ?? error.localizedDescription
        }
    }
}
