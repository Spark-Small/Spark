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
        presentation.endComposeClub()
        persist()
        onMembershipChanged?()

        presentation.pendingOrgJoinSuccess = BuddyOrgJoinSuccess(
            kind: .circle,
            name: circle.name,
            systemImage: circle.systemImage
        )
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
}
