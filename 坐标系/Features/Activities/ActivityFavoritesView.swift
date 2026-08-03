//
//  ActivityFavoritesView.swift
//  坐标系
//
//  活动页「更多」入口：收藏的活动（与「我的内容库」共用列表）。
//

import SwiftUI

struct ActivityFavoritesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // Sheet 自有栈：清掉外层已注册标记，避免 Zoom 目的地被跳过
            ProfileFavoriteActivitiesLibraryView()
                .environment(\.activityZoomNamespace, nil)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { dismiss() }
                    }
                }
        }
        .platformSheet(.browser)
    }
}
