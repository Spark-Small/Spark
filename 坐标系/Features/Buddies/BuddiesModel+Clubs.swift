//
//  BuddiesModel+Clubs.swift
//  坐标系
//
//  俱乐部目录、创建与用户俱乐部管理。
//

import Foundation
import CoordinateModels

extension BuddiesModel {
    var catalogCircles: [InterestCircle] {
        ClubCatalog.allCircles(including: userClubs)
    }

    func circle(id: UUID) -> InterestCircle? {
        ClubCatalog.circle(id: id, userClubs: userClubs)
    }

    func circle(named name: String) -> InterestCircle? {
        ClubCatalog.circle(named: name, userClubs: userClubs)
    }

    func relatedCircle(for activity: Activity) -> InterestCircle? {
        SampleData.relatedCircle(for: activity, userClubs: userClubs)
    }

    var hostedClubs: [InterestCircle] {
        userClubs
            .filter { $0.isCreator(currentUserName) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 「我的俱乐部」：我创建的在前，其余已加入在后。
    var membershipClubs: [InterestCircle] {
        let hosted = hostedClubs
        let hostedIDs = Set(hosted.map(\.id))
        let joined = joinedCircleIDs
            .compactMap { circle(id: $0) }
            .filter { !hostedIDs.contains($0.id) }
            .sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        return hosted + joined
    }

    func isUserCreatedClub(_ circle: InterestCircle) -> Bool {
        userClubs.contains { $0.id == circle.id }
    }

    func validateClubName(_ raw: String) -> String? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.count < 2 { return BuddyBrowseCopy.ModelCopy.clubNameTooShort }
        if name.count > 20 { return BuddyBrowseCopy.ModelCopy.clubNameTooLong }
        if catalogCircles.contains(where: {
            $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }) {
            return BuddyBrowseCopy.ModelCopy.clubNameTaken
        }
        return nil
    }

    @discardableResult
    func createClub(
        name: String,
        topic: String,
        city: String,
        summary: String,
        tags: [String],
        systemImage: String
    ) -> InterestCircle? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateClubName(trimmedName) == nil else { return nil }

        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSummary.count >= 8 else { return nil }

        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return nil }

        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty else { return nil }

        let circle = InterestCircle(
            id: UUID(),
            name: trimmedName,
            topic: trimmedTopic,
            city: trimmedCity,
            memberCount: 1,
            weeklyActive: 1,
            tags: tags,
            summary: trimmedSummary,
            systemImage: systemImage,
            creatorName: currentUserName,
            createdAt: Date()
        )

        userClubs.append(circle)
        joinedCircleIDs.insert(circle.id)
        joinedCircleNames.insert(circle.name)
        ensurePrefs(kind: .circle, name: circle.name)
        persist()
        onMembershipChanged?()

        // 创建成功由「我的俱乐部」Sheet 回调导航进圈子；不挂搭子 Tab 成功 Sheet（避免换 Tab 脏弹）。
        flash(BuddyOrgJoinCopy.createdClub(circle.name))
        if remoteClubSync.isEnabled {
            Task { await submitClubCreateToRemote(circle.id) }
        }
        return circle
    }

    func submitClubCreateToRemote(_ id: UUID) async {
        guard remoteClubSync.isEnabled,
              let club = userClubs.first(where: { $0.id == id }) else { return }
        do {
            let remote = try await remoteClubSync.create(club, creatorUserID: currentUserID)
            if let index = userClubs.firstIndex(where: { $0.id == id }) {
                userClubs[index] = remote
                persist()
            }
        } catch {
            flash(BuddyFeedbackCopy.remoteClubSyncFailed)
        }
    }

    func dissolveUserClub(_ circle: InterestCircle) {
        guard isUserCreatedClub(circle) else { return }
        userClubs.removeAll { $0.id == circle.id }
        joinedCircleIDs.remove(circle.id)
        joinedCircleNames.remove(circle.name)
        membershipPrefs.removeValue(forKey: OrgMembershipKind.circle.prefsKey(name: circle.name))
        persist()
        onMembershipChanged?()
    }

    /// 改昵称后同步自建俱乐部 `creatorName`，避免详情仍显示旧名。
    func migrateUserName(from oldName: String, to newName: String) {
        guard !oldName.isEmpty, !newName.isEmpty,
              oldName.caseInsensitiveCompare(newName) != .orderedSame
        else { return }
        var changed = false
        for index in userClubs.indices {
            if userClubs[index].creatorName.caseInsensitiveCompare(oldName) == .orderedSame {
                userClubs[index].creatorName = newName
                changed = true
            }
        }
        if currentUserName.caseInsensitiveCompare(oldName) == .orderedSame {
            currentUserName = newName
        }
        if changed { persist() }
    }

    func migrateJoinedCircleMembershipIfNeeded() {
        guard joinedCircleIDs.isEmpty, !joinedCircleNames.isEmpty else { return }
        for name in joinedCircleNames {
            if let circle = circle(named: name) {
                joinedCircleIDs.insert(circle.id)
            }
        }
    }

    func syncJoinedCircleNamesFromIDs() {
        let names = joinedCircleIDs.compactMap { circle(id: $0)?.name }
        joinedCircleNames = Set(names)
    }

    /// 与俱乐部详情标题人数同源：会话/名册他人数 +（已加入则含自己）；无名单时回落种子。
    func displayedMemberCount(
        for circle: InterestCircle,
        messages: MessagesModel,
        viewerName: String
    ) -> Int {
        let joined = isJoined(circle)
        var others = 0
        if let conversation = messages.conversation(forCircleID: circle.id) {
            others = messages.groupMembers(for: conversation.id).filter {
                $0.nickname.caseInsensitiveCompare(viewerName) != .orderedSame
            }.count
        } else if BuddiesSupplyPolicy.allowsSampleDiscoverCatalog {
            others = SampleData.circleBuddies.filter { $0.circleName == circle.name }.count
        }
        let rosterBased = others + (joined ? 1 : 0)
        if rosterBased > 0 { return rosterBased }
        return max(circle.memberCount, joined ? 1 : 0)
    }
}
