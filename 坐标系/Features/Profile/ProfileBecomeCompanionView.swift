//
//  ProfileBecomeCompanionView.swift
//  坐标系
//
//  成为陪玩入口。
//

import CoordinateModels
import SwiftUI

/// 「成为陪玩」入驻占位：前期只保留入口与说明，正式版再接审核流。
struct ProfileBecomeCompanionView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ProfileLibraryEmptyView(
            title: ProfileDashboardCopy.becomeCompanion,
            systemImage: "person.badge.plus",
            description: "完善资料并通过审核后，即可在陪玩页接单。入驻流程将在正式版开放。"
        ) {
            Button("去预约页看看") {
                app.pendingBuddiesRoute = .paidBrowse
                app.selectedTab = .buddies
            }
        }
        .navigationTitle(ProfileDashboardCopy.becomeCompanion)
        .navigationBarTitleDisplayMode(.inline)
    }
}
