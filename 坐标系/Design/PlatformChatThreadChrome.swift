//
//  PlatformChatThreadChrome.swift
//  坐标系
//
//  聊天线程：日期分隔、系统提示、空态、气泡 chrome 模型。
//

import SwiftUI
import CoordinateModels

struct PlatformChatDaySeparator: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.vertical, PlatformMessagesChrome.daySeparatorVerticalPadding)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }
}

/// 系统提示小字（进群 / 退群等）
struct PlatformChatSystemTip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMessagesChrome.daySeparatorVerticalPadding)
            .accessibilityLabel(text)
    }
}

struct PlatformChatEmptyThread: View {
    let peerName: String

    var body: some View {
        ContentUnavailableView {
            Label(MessagesCopy.emptyThreadTitle, systemImage: "hand.wave")
        } description: {
            Text(MessagesCopy.emptyThreadDescription(peerName: peerName))
        }
        .padding(.vertical, PlatformMessagesChrome.emptyVerticalPadding)
    }
}

/// 气泡展示：群聊对方头像 + 连续消息聚类（信息 App 范式）
struct PlatformChatBubbleChrome: Equatable {
    var showsSenderName: Bool
    var showsLeadingAvatar: Bool
    var showsTrailingAvatar: Bool
    var reservesLeadingAvatar: Bool
    var reservesTrailingAvatar: Bool
    var isClusterContinuation: Bool
    var isNotice: Bool
}
