//
//  BuddiesSnapshotCatalog.swift
//  坐标系
//

import CoordinateData
import CoordinateModels

enum BuddiesSnapshotCatalog {
    /// 目录升级：空库写种子；已有数据按 ID 补齐缺失种子预约 / 邀约。
    /// Release 种子为空，不会向正式用户注入虚构订单。
    static func mergeCatalog(into previous: BuddiesSnapshot) -> BuddiesSnapshot? {
        let seed = BuddiesSnapshot.seed
        #if !DEBUG
        // Release：永不从种子补齐虚构邀约 / 预约。
        if previous.inviteRecords.isEmpty && previous.bookingRecords.isEmpty
            && previous.clubs.isEmpty && previous.joinedCircleIDs.isEmpty {
            return seed
        }
        return nil
        #else
        if previous.inviteRecords.isEmpty && previous.bookingRecords.isEmpty {
            return seed
        }

        let existingBookingIDs = Set(previous.bookingRecords.map(\.id))
        let missingBookings = seed.bookingRecords.filter { !existingBookingIDs.contains($0.id) }
        let existingInviteIDs = Set(previous.inviteRecords.map(\.id))
        let missingInvites = seed.inviteRecords.filter { !existingInviteIDs.contains($0.id) }
        guard !missingBookings.isEmpty || !missingInvites.isEmpty else { return nil }

        return BuddiesSnapshot(
            inviteRecords: previous.inviteRecords + missingInvites,
            bookingRecords: missingBookings + previous.bookingRecords,
            clubs: previous.clubs,
            joinedCircleIDs: previous.joinedCircleIDs,
            joinedCircleNames: previous.joinedCircleNames,
            joinedGuildNames: previous.joinedGuildNames,
            membershipPrefs: previous.membershipPrefs
        )
        #endif
    }
}

struct AppBuddiesSnapshotPolicy: BuddiesSnapshotPersistencePolicy {
    func fallbackSnapshot() -> BuddiesSnapshot { .seed }
}
