//
//  AppTips.swift
//  坐标系
//
//  TipKit：活动筛选、会员开通首次引导。
//

import SwiftUI
import TipKit
import CoordinateModels

struct ActivityFilterTip: Tip {
    var title: Text {
        Text("按条件找局")
    }

    var message: Text? {
        Text("用筛选缩小日期、费用与距离，更快找到想参加的活动。")
    }

    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease")
    }
}

struct MembershipTip: Tip {
    var title: Text {
        Text("开通会员")
    }

    var message: Text? {
        Text("订阅后可展示会员标识，并获得活动优先提醒等权益。")
    }

    var image: Image? {
        Image(systemName: "checkmark.seal.fill")
    }
}

enum AppTips {
    static func configure() {
        try? Tips.configure([
            .displayFrequency(.daily)
        ])
    }
}
