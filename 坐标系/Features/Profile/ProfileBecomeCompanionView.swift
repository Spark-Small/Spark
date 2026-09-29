//
//  ProfileBecomeCompanionView.swift
//  坐标系
//
//  成为陪玩入口。
//

import CoordinateModels
import SwiftUI
import TipKit

// MARK: - Become companion

/// 「成为陪玩」入驻占位：前期只保留入口与说明，正式版再接审核流。
struct ProfileBecomeCompanionView: View {
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            Section {
                ContentUnavailableView(
                    ProfileDashboardCopy.becomeCompanion,
                    systemImage: "person.badge.plus",
                    description: Text("完善资料并通过审核后，即可在陪玩页接单。入驻流程将在正式版开放。")
                )
                .listRowBackground(Color.clear)

                Button("去预约页看看") {
                    buddies.showPaidPage()
                    app.selectedTab = .buddies
                }
                .activityPrimaryCTA(controlSize: .large)
                .buttonSizing(.flexible)
                .listRowBackground(Color.clear)
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.becomeCompanion)
        .navigationBarTitleDisplayMode(.inline)
    }
}
