// Module: SparkActivity — Mock who-is-going rows for detail previews.

import Foundation

enum MockActivityAttendees {
    static func roster(host: String, members: [String]) -> [ActivityAttendee] {
        roster(host: host, members: members.map { ($0, false) })
    }

    static func roster(host: String, members: [(name: String, verified: Bool)]) -> [ActivityAttendee] {
        var list = [ActivityAttendee(id: "host_\(host)", displayName: host, isHost: true)]
        for (index, member) in members.enumerated() {
            list.append(
                ActivityAttendee(
                    id: "member_\(index)_\(member.name)",
                    displayName: member.name,
                    isVerified: member.verified
                )
            )
        }
        return list
    }

    static func hostRoster(
        host: String,
        members: [(name: String, status: ActivityRSVPStatus)]
    ) -> [ActivityAttendee] {
        var list = [ActivityAttendee(id: "host_\(host)", displayName: host, isHost: true, rsvpStatus: .host)]
        for (index, member) in members.enumerated() {
            list.append(
                ActivityAttendee(
                    id: "member_\(index)_\(member.name)",
                    displayName: member.name,
                    rsvpStatus: member.status
                )
            )
        }
        return list
    }
}
