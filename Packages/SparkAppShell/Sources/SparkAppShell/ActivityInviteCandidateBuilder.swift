// Module: SparkAppShell — Build activity invite candidates from messages inbox.

import SparkActivity
import SparkMessages

enum ActivityInviteCandidateBuilder {
    @MainActor
    static func from(messagesViewModel: MessagesViewModel?) -> [ActivityInviteCandidate] {
        guard let messagesViewModel else { return [] }
        var seen = Set<String>()
        var results: [ActivityInviteCandidate] = []

        for match in messagesViewModel.unmessagedMatches {
            guard seen.insert(match.user.id).inserted else { continue }
            results.append(
                ActivityInviteCandidate(
                    id: match.user.id,
                    displayName: match.user.displayName,
                    avatarURL: match.user.avatarURL
                )
            )
        }

        for conversation in messagesViewModel.dmConversations where conversation.kind == .dm {
            if let partner = conversation.dmPartner, seen.insert(partner.id).inserted {
                results.append(
                    ActivityInviteCandidate(
                        id: partner.id,
                        displayName: partner.displayName,
                        avatarURL: partner.avatarURL
                    )
                )
            }
        }

        return results.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }
}
