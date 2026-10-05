//
//  BlockedUsersView.swift
//  坐标系
//
//  设置 · 已拉黑。
//

import SwiftUI
import UIKit
import CoordinateModels

struct BlockedUsersView: View {
    @Environment(AppModel.self) private var app
    @State private var pendingUnblockName: String?

    var body: some View {
        Group {
            if app.blockedUserNames.isEmpty {
                ProfileLibraryEmptyView(
                    title: "未拉黑任何人",
                    systemImage: "person.crop.circle.badge.checkmark",
                    description: "被你拉黑的人会出现在这里。"
                )
            } else {
                List {
                    ForEach(Array(app.blockedUserNames).sorted(), id: \.self) { name in
                        Text(name)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("解除", role: .destructive) {
                                    pendingUnblockName = name
                                }
                            }
                    }
                }
                .profileSecondaryListChrome()
            }
        }
        .navigationTitle("已拉黑")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("解除拉黑？", isPresented: Binding(
            get: { pendingUnblockName != nil },
            set: { if !$0 { pendingUnblockName = nil } }
        )) {
            Button("解除", role: .destructive) {
                if let pendingUnblockName {
                    app.unblockUser(pendingUnblockName)
                }
                pendingUnblockName = nil
            }
            Button("取消", role: .cancel) {
                pendingUnblockName = nil
            }
        } message: {
            Text(pendingUnblockName.map { "将解除对 \($0) 的拉黑。" } ?? "")
        }
    }
}

func moderationStatusColor(_ status: ModerationTicketStatus) -> Color {
    switch status {
    case .received: .orange
    case .reviewing: .blue
    case .resolved: PlatformStatus.success
    case .rejected: .secondary
    }
}
