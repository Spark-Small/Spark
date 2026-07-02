// Module: SparkCommunity — Reply ordering for linked-activity recap threads.

import Foundation

public enum CommunityPostReplySortMode: String, CaseIterable, Identifiable, Sendable {
    case participantsFirst
    case newest

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .participantsFirst:
            String(
                localized: "community.replies.sort.participantsFirst",
                defaultValue: "参与者优先",
                comment: "Sort replies with linked-activity participants first"
            )
        case .newest:
            String(
                localized: "community.replies.sort.newest",
                defaultValue: "最新",
                comment: "Sort replies by newest first"
            )
        }
    }
}

enum CommunityPostReplySorting {
    static func sorted(
        _ replies: [CommunityPostReply],
        mode: CommunityPostReplySortMode
    ) -> [CommunityPostReply] {
        switch mode {
        case .participantsFirst:
            replies.sorted { lhs, rhs in
                let lhsParticipant = lhs.relationshipToViewer == .attendedLinkedActivity
                let rhsParticipant = rhs.relationshipToViewer == .attendedLinkedActivity
                if lhsParticipant != rhsParticipant {
                    return lhsParticipant && !rhsParticipant
                }
                return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
        case .newest:
            replies.sorted {
                ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            }
        }
    }
}
