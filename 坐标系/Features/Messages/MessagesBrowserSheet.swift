//
//  MessagesBrowserSheet.swift
//  坐标系
//
//  消息模块 Sheet：browser（plain 列表）/ form（insetGrouped 设置感）。
//

import SwiftUI
import CoordinateModels

enum MessagesSheetDismissAction {
    case close
    case cancel
}

struct MessagesBrowserSheet<Content: View>: View {
    let title: String
    var dismissAction: MessagesSheetDismissAction = .close
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content()
                .platformConversationListChrome()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(dismissLabel) { dismiss() }
                    }
                }
        }
        .platformSheet(.browser)
    }

    private var dismissLabel: String {
        switch dismissAction {
        case .close: MessagesCopy.close
        case .cancel: MessagesCopy.cancel
        }
    }
}

/// 消息设置 / 请求类 Sheet：系统 insetGrouped + `.form` 高度档。
struct MessagesFormSheet<Content: View>: View {
    let title: String
    var dismissAction: MessagesSheetDismissAction = .close
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content()
                .listStyle(.insetGrouped)
                .scrollContentBackground(.visible)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(dismissLabel) { dismiss() }
                    }
                }
        }
        .platformSheet(.form)
    }

    private var dismissLabel: String {
        switch dismissAction {
        case .close: MessagesCopy.close
        case .cancel: MessagesCopy.cancel
        }
    }
}

extension View {
    func messagesListRow() -> some View {
        platformConversationListRowChrome()
    }
}
