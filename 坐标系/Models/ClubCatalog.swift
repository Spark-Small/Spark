//
//  ClubCatalog.swift
//  坐标系
//
//  种子俱乐部 + 用户创建俱乐部合并目录。
//

import Foundation
import CoordinateModels

enum ClubCatalog {
    static func allCircles(including userClubs: [InterestCircle]) -> [InterestCircle] {
        var seen = Set<UUID>()
        var result: [InterestCircle] = []
        for circle in SampleData.interestCircles + userClubs {
            guard seen.insert(circle.id).inserted else { continue }
            result.append(circle)
        }
        return result
    }

    static func circle(id: UUID, userClubs: [InterestCircle]) -> InterestCircle? {
        if let match = userClubs.first(where: { $0.id == id }) { return match }
        return SampleData.interestCircles.first { $0.id == id }
    }

    static func circle(named name: String, userClubs: [InterestCircle]) -> InterestCircle? {
        if let match = userClubs.first(where: { $0.name == name }) { return match }
        return SampleData.interestCircles.first { $0.name == name }
    }
}
