//
//  GroupNicknameDisplay.swift
//  坐标系
//
//  群聊昵称展示：真实昵称（群昵称），如 林屿（雪碧）。
//

import Foundation
import CoordinateModels

enum GroupNicknameDisplay {
    static func formatted(realName: String, groupAlias: String?) -> String {
        let name = realName.trimmingCharacters(in: .whitespacesAndNewlines)
        let alias = groupAlias?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return alias }
        guard !alias.isEmpty, alias.caseInsensitiveCompare(name) != .orderedSame else {
            return name
        }
        return "\(name)（\(alias)）"
    }

    /// 设置页「我在本群昵称」展示：未单独设置时回退真实昵称
    static func settingsValue(realName: String, myGroupNickname: String) -> String {
        let custom = myGroupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? realName : custom
    }
}
