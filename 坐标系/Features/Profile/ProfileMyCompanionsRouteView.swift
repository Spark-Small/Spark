//
//  ProfileMyCompanionsRouteView.swift
//  坐标系
//
//  「我的陪玩」路由壳：有待确认 / 待支付时默认打开「待处理」分类。
//

import SwiftUI

struct ProfileMyCompanionsRouteView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        ProfileMyCompanionsView(
            initialCategory: buddies.pendingBookingAttentionCount > 0 ? .pending : .upcoming
        )
    }
}
