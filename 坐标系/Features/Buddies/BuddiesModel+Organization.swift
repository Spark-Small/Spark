//
//  BuddiesModel+Organization.swift
//  坐标系
//
//  俱乐部 / 工会成员关系与偏好。
//

import Foundation
import CoordinateModels

extension BuddiesModel {
    var joinedCircles: [InterestCircle] {
        joinedCircleIDs
            .compactMap { circle(id: $0) }
            .sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    var joinedGuilds: [CompanionGuild] {
        guard BuddiesSupplyPolicy.allowsSampleDiscoverCatalog else { return [] }
        return SampleData.companionGuilds.filter { joinedGuildNames.contains($0.name) }
    }

    func isJoined(_ circle: InterestCircle) -> Bool {
        joinedCircleIDs.contains(circle.id)
    }

    func isJoined(_ guild: CompanionGuild) -> Bool {
        joinedGuildNames.contains(guild.name)
    }

    func beginJoin(_ target: BuddyOrgJoinTarget) {
        switch target {
        case .circle(let circle) where isJoined(circle):
            return
        case .guild(let guild) where isJoined(guild):
            return
        default:
            presentation.pendingOrgJoin = target
        }
    }

    @discardableResult
    func confirmJoin() -> BuddyOrgJoinSuccess? {
        guard let pending = presentation.pendingOrgJoin else { return nil }
        switch pending {
        case .circle(let circle):
            joinedCircleIDs.insert(circle.id)
            joinedCircleNames.insert(circle.name)
            ensurePrefs(kind: .circle, name: circle.name)
            presentation.pendingOrgJoin = nil
            let success = BuddyOrgJoinSuccess(kind: .circle, name: circle.name, systemImage: circle.systemImage)
            presentation.pendingOrgJoinSuccess = success
            persist()
            onMembershipChanged?()
            flash(BuddyOrgJoinCopy.joinedClub(circle.name))
            if remoteClubSync.isEnabled {
                Task { await submitClubJoinToRemote(circle.id) }
            }
            return success
        case .guild(let guild):
            joinedGuildNames.insert(guild.name)
            ensurePrefs(kind: .guild, name: guild.name)
            presentation.pendingOrgJoin = nil
            let success = BuddyOrgJoinSuccess(kind: .guild, name: guild.name, systemImage: guild.systemImage)
            presentation.pendingOrgJoinSuccess = success
            persist()
            onMembershipChanged?()
            flash(BuddyOrgJoinCopy.followedGuild(guild.name))
            return success
        }
    }

    func submitClubJoinToRemote(_ circleID: UUID) async {
        guard remoteClubSync.isEnabled else { return }
        do {
            try await remoteClubSync.join(circleID: circleID)
        } catch {
            flash(BuddyFeedbackCopy.remoteClubSyncFailed)
        }
    }

    func cancelJoin() {
        presentation.pendingOrgJoin = nil
    }

    func dismissJoinSuccess() {
        presentation.pendingOrgJoinSuccess = nil
        pendingOpenConversationID = nil
    }

    func attachJoinConversation(_ conversationID: UUID) {
        pendingOpenConversationID = conversationID
    }

    func leaveCircle(_ circle: InterestCircle) {
        joinedCircleIDs.remove(circle.id)
        joinedCircleNames.remove(circle.name)
        membershipPrefs.removeValue(forKey: OrgMembershipKind.circle.prefsKey(name: circle.name))
        persist()
        onMembershipChanged?()
        flash(BuddyOrgJoinCopy.leftClub(circle.name))
        if remoteClubSync.isEnabled {
            Task { await submitClubLeaveToRemote(circle.id) }
        }
    }

    func submitClubLeaveToRemote(_ circleID: UUID) async {
        guard remoteClubSync.isEnabled else { return }
        do {
            try await remoteClubSync.leave(circleID: circleID)
        } catch {
            flash(BuddyFeedbackCopy.remoteClubSyncFailed)
        }
    }

    func leaveGuild(_ guild: CompanionGuild) {
        joinedGuildNames.remove(guild.name)
        membershipPrefs.removeValue(forKey: OrgMembershipKind.guild.prefsKey(name: guild.name))
        persist()
        onMembershipChanged?()
        flash(BuddyOrgJoinCopy.unfollowedGuild(guild.name))
    }

    func prefs(kind: OrgMembershipKind, name: String) -> OrgMembershipPrefs {
        membershipPrefs[kind.prefsKey(name: name)] ?? .fresh()
    }

    func updatePrefs(kind: OrgMembershipKind, name: String, _ mutate: (inout OrgMembershipPrefs) -> Void) {
        let key = kind.prefsKey(name: name)
        var value = membershipPrefs[key] ?? .fresh()
        mutate(&value)
        membershipPrefs[key] = value
        persist()
    }

    func beginInvite(to target: BuddyOrgInviteTarget) {
        presentation.pendingOrgInvite = target
    }

    func sendOrgInvites(nicknames: [String]) {
        guard let target = presentation.pendingOrgInvite, !nicknames.isEmpty else {
            presentation.pendingOrgInvite = nil
            return
        }
        presentation.pendingOrgInvite = nil
        let label: String
        switch target {
        case .circle(let circle): label = circle.name
        case .guild(let guild): label = guild.name
        }
        flash(BuddyOrgJoinCopy.invitedCount(nicknames.count, label: label))
    }

    func ensurePrefs(kind: OrgMembershipKind, name: String) {
        let key = kind.prefsKey(name: name)
        if membershipPrefs[key] == nil {
            membershipPrefs[key] = .fresh()
        }
    }
}
