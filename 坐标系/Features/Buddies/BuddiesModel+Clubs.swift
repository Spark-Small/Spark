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
        if name.count < 2 { return "名称至少 2 个字" }
        if name.count > 20 { return "名称不超过 20 个字" }
        if catalogCircles.contains(where: {
            $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }) {
            return "已有同名俱乐部，请换一个名称"
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
        isComposingClub = false
        persist()
        onMembershipChanged?()

        pendingOrgJoinSuccess = BuddyOrgJoinSuccess(
            kind: .circle,
            name: circle.name,
            systemImage: circle.systemImage
        )
        flash("已创建「\(circle.name)」")
        return circle
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
