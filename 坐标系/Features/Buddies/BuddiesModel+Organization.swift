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
        SampleData.companionGuilds.filter { joinedGuildNames.contains($0.name) }
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
            pendingOrgJoin = target
        }
    }

    @discardableResult
    func confirmJoin() -> BuddyOrgJoinSuccess? {
        guard let pending = pendingOrgJoin else { return nil }
        switch pending {
        case .circle(let circle):
            joinedCircleIDs.insert(circle.id)
            joinedCircleNames.insert(circle.name)
            ensurePrefs(kind: .circle, name: circle.name)
            pendingOrgJoin = nil
            let success = BuddyOrgJoinSuccess(kind: .circle, name: circle.name, systemImage: circle.systemImage)
            pendingOrgJoinSuccess = success
            persist()
            onMembershipChanged?()
            flash("已加入「\(circle.name)」")
            return success
        case .guild(let guild):
            joinedGuildNames.insert(guild.name)
            ensurePrefs(kind: .guild, name: guild.name)
            pendingOrgJoin = nil
            let success = BuddyOrgJoinSuccess(kind: .guild, name: guild.name, systemImage: guild.systemImage)
            pendingOrgJoinSuccess = success
            persist()
            onMembershipChanged?()
            flash("已关注「\(guild.name)」")
            return success
        }
    }

    func cancelJoin() {
        pendingOrgJoin = nil
    }

    func dismissJoinSuccess() {
        pendingOrgJoinSuccess = nil
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
        flash("已退出「\(circle.name)」")
    }

    func leaveGuild(_ guild: CompanionGuild) {
        joinedGuildNames.remove(guild.name)
        membershipPrefs.removeValue(forKey: OrgMembershipKind.guild.prefsKey(name: guild.name))
        persist()
        onMembershipChanged?()
        flash("已取消关注「\(guild.name)」")
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
        pendingOrgInvite = target
    }

    func sendOrgInvites(nicknames: [String]) {
        guard let target = pendingOrgInvite, !nicknames.isEmpty else {
            pendingOrgInvite = nil
            return
        }
        pendingOrgInvite = nil
        let label: String
        switch target {
        case .circle(let circle): label = circle.name
        case .guild(let guild): label = guild.name
        }
        flash("已邀请 \(nicknames.count) 人加入「\(label)」")
    }

    func ensurePrefs(kind: OrgMembershipKind, name: String) {
        let key = kind.prefsKey(name: name)
        if membershipPrefs[key] == nil {
            membershipPrefs[key] = .fresh()
        }
    }
}
