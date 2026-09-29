//
//  ActivityDetailDraftRows.swift
//  坐标系
//
//  活动内容编辑用的行程 / 装备草稿行。
//

import Foundation

struct TimelineDraftRow: Identifiable, Hashable {
    let id: UUID
    var time: String
    var title: String
    var detail: String

    init(id: UUID = UUID(), time: String, title: String, detail: String) {
        self.id = id
        self.time = time
        self.title = title
        self.detail = detail
    }
}

struct GearDraftRow: Identifiable, Hashable {
    let id: UUID
    var title: String
    var detail: String
    var systemImage: String

    init(id: UUID = UUID(), title: String, detail: String, systemImage: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }
}

let gearIconOptions = [
    "backpack", "shoeprints.fill", "tshirt", "drop", "sun.max", "bag",
    "book", "battery.100", "figure.walk", "cup.and.saucer", "paintbrush.pointed", "fork.knife"
]
