//
//  TrustPublicCredentials.swift
//  坐标系
//
//  对外形象认证 / 会员状态解析（自己读本机；他人读档案信号）。
//

import Foundation

enum TrustPublicCredentials {
    struct Flags: Hashable {
        var photoVerified: Bool
        var isMember: Bool
    }

    @MainActor
    static func flags(
        nickname: String,
        currentUserName: String,
        buddyItem: DiscoverBuddyItem?,
        membershipActive: Bool,
        liveHostedCount: Int = 1
    ) -> Flags {
        let isSelf = nickname.caseInsensitiveCompare(currentUserName) == .orderedSame
        if isSelf {
            return Flags(
                photoVerified: PhotoVerificationStore.shared.isVerified(for: nickname),
                isMember: membershipActive
            )
        }

        switch buddyItem {
        case .paid(let companion):
            let host = ActivityHostTrust.make(hostName: nickname, liveHostedCount: liveHostedCount)
            return Flags(
                photoVerified: companion.isVerified,
                isMember: host.isMember || companion.orderCount >= 50
            )
        case .free:
            let seed = abs(nickname.stableSeed)
            return Flags(
                photoVerified: seed % 3 == 0,
                isMember: seed % 2 == 0
            )
        case .none:
            let host = ActivityHostTrust.make(hostName: nickname, liveHostedCount: liveHostedCount)
            return Flags(
                photoVerified: host.isVerified,
                isMember: host.isMember
            )
        }
    }
}

extension TrustPublicCard {
    var photoVerified: Bool {
        badges.contains { $0.kind == .photoVerified }
    }

    var isMember: Bool {
        badges.contains { $0.kind == .activeMember }
    }
}
