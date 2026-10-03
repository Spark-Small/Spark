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
        Text("点筛选即可按时间、距离和费用缩小范围，选完立即生效。")
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
