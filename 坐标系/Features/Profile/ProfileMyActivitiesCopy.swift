//
//  ProfileMyActivitiesCopy.swift
//  坐标系
//
//  「我的活动」文案：分类走顶栏 Menu；横卡角标走 `ActivityCardStatus`（见 StatusPresentation）。
//

import Foundation

enum ProfileMyActivitiesCopy {
    static let navigationTitle = "我的活动"
    static let pickerAccessibility = "活动分类"

    static let emptyUpcomingTitle = "暂无即将开始的活动"
    static let emptyUpcomingDescription = "参加、候补或发起一场活动后，会按时间出现在这里。"
    static let emptyAttendingTitle = "还没有报名的活动"
    static let emptyAttendingDescription = "去活动页报名或候补一场局，行程会出现在这里。"
    static let emptyHostingTitle = "还没有发起的活动"
    static let emptyHostingDescription = "在活动页发起一场局后，会出现在这里。"
    static let emptyPastTitle = "暂无已结束的活动"
    static let emptyPastDescription = "参加、候补或发起过的活动结束后会出现在这里。"

    static let browseDiscover = "去发现活动"

    /// 顶栏 Menu 四类：即将开始 / 我报名的 / 我发起的 / 已经结束。
    enum Category: String, CaseIterable, Identifiable, Hashable {
        case upcoming
        case attending
        case hosting
        case past

        var id: String { rawValue }

        var segmentTitle: String {
            switch self {
            case .upcoming: "即将开始"
            case .attending: "我报名的"
            case .hosting: "我发起的"
            case .past: "已经结束"
            }
        }

        var emptyTitle: String {
            switch self {
            case .upcoming: emptyUpcomingTitle
            case .attending: emptyAttendingTitle
            case .hosting: emptyHostingTitle
            case .past: emptyPastTitle
            }
        }

        var emptyDescription: String {
            switch self {
            case .upcoming: emptyUpcomingDescription
            case .attending: emptyAttendingDescription
            case .hosting: emptyHostingDescription
            case .past: emptyPastDescription
            }
        }

        var systemImage: String {
            switch self {
            case .upcoming: "calendar"
            case .attending: "person.crop.circle.badge.checkmark"
            case .hosting: "flag"
            case .past: "clock.arrow.circlepath"
            }
        }

        var emptySystemImage: String { systemImage }
    }
}
