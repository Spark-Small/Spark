//
//  MessagesTimeline.swift
//  坐标系
//
//  会话线程时间线：日期分隔 / 系统提示 / 气泡聚类。
//

import Foundation
import SwiftUI

enum ChatTimelineItem: Identifiable {
    case day(String, id: String)
    case tip(ChatMessage)
    case message(ChatMessage, chrome: PlatformChatBubbleChrome)

    var id: String {
        switch self {
        case .day(_, let id): id
        case .tip(let message): message.id.uuidString
        case .message(let message, _): message.id.uuidString
        }
    }

    static func build(
        from messages: [ChatMessage],
        isGroup: Bool,
        isNotice: Bool
    ) -> [ChatTimelineItem] {
        var items: [ChatTimelineItem] = []
        var lastDay: DateComponents?
        let calendar = Calendar.current
        let clusterGap = PlatformMessagesChrome.clusterGap
        let timestampGap = PlatformMessagesChrome.timestampGap

        for (index, message) in messages.enumerated() {
            let previous = index > 0 ? messages[index - 1] : nil
            let next = index + 1 < messages.count ? messages[index + 1] : nil
            let gapFromPrevious = previous.map { message.sentAt.timeIntervalSince($0.sentAt) } ?? .infinity
            let gapToNext = next.map { $0.sentAt.timeIntervalSince(message.sentAt) } ?? .infinity

            let day = calendar.dateComponents([.year, .month, .day], from: message.sentAt)
            if day != lastDay {
                items.append(.day(Self.dayLabel(for: message.sentAt), id: "day-\(message.id)"))
                lastDay = day
            } else if !message.isSystem, gapFromPrevious >= timestampGap {
                items.append(
                    .day(
                        Formatters.shortTime.string(from: message.sentAt),
                        id: "time-\(message.id)"
                    )
                )
            }

            if message.isSystem {
                items.append(.tip(message))
                continue
            }
            if isNotice {
                items.append(.message(message, chrome: PlatformChatBubbleChrome.notice))
                continue
            }

            let continuesFromPrevious = previous.map {
                !$0.isSystem
                    && $0.sender == message.sender
                    && $0.isMe == message.isMe
                    && gapFromPrevious < clusterGap
            } ?? false

            let continuesToNext = next.map {
                !$0.isSystem
                    && $0.sender == message.sender
                    && $0.isMe == message.isMe
                    && gapToNext < clusterGap
            } ?? false

            let chrome = PlatformChatBubbleChrome(
                showsSenderName: isGroup && !message.isMe && !continuesFromPrevious,
                showsLeadingAvatar: isGroup && !message.isMe && !continuesToNext,
                showsTrailingAvatar: false,
                reservesLeadingAvatar: isGroup && !message.isMe,
                reservesTrailingAvatar: false,
                isClusterContinuation: continuesFromPrevious,
                isNotice: false
            )
            items.append(.message(message, chrome: chrome))
        }
        return items
    }

    private static func dayLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return MessagesCopy.dayToday }
        if Calendar.current.isDateInYesterday(date) { return MessagesCopy.dayYesterday }
        return "\(Formatters.monthDay.string(from: date)) \(Formatters.weekday.string(from: date))"
    }
}

extension PlatformChatBubbleChrome {
    static let notice = PlatformChatBubbleChrome(
        showsSenderName: false,
        showsLeadingAvatar: false,
        showsTrailingAvatar: false,
        reservesLeadingAvatar: false,
        reservesTrailingAvatar: false,
        isClusterContinuation: false,
        isNotice: true
    )
}

extension ChatConversation {
    /// 导航栏副标题：群主可见「群主 · 时间」；好友可见在线
    func navigationSubtitle(viewerName: String) -> String {
        switch kind {
        case .activity:
            let time: String = {
                if let eventAt {
                    return Formatters.activityEventTime(from: eventAt)
                }
                return MessagesCopy.groupSubtitle
            }()
            if isOwned(by: viewerName) {
                return "\(MessagesCopy.groupOwnerBadge) · \(time)"
            }
            return time
        case .group:
            if isOwned(by: viewerName) {
                return "\(MessagesCopy.groupOwnerBadge) · \(MessagesCopy.groupSubtitle)"
            }
            return MessagesCopy.groupSubtitle
        case .circle:
            if isOwned(by: viewerName) {
                return "\(MessagesCopy.groupOwnerBadge) · \(MessagesCopy.circleGroupSubtitle)"
            }
            return MessagesCopy.circleGroupSubtitle
        case .direct:
            return peerIsActive ? MessagesCopy.activeNow : MessagesCopy.friendSubtitle
        case .notice:
            return MessagesCopy.noticeSubtitle
        }
    }
}
