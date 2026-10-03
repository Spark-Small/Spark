//
//  BuddyPersonBrowseContextMenu.swift
//  坐标系
//
//  搭子发现人像卡长按：联系 / 预约 / 分享（与详情主动词对齐）。
//

import SwiftUI
import CoordinateModels

struct BuddyPersonBrowseContextActions {
    var contactTitle: String
    var onContact: () -> Void
    var onBook: (() -> Void)?
    var shareText: String

    @MainActor
    static func make(
        item: DiscoverBuddyItem,
        contactTitle: String,
        onContact: @escaping () -> Void,
        onBook: (() -> Void)?
    ) -> BuddyPersonBrowseContextActions {
        let meta = BuddyPersonBrowseChrome.metaLine(for: item)
        let share: String = {
            if meta.isEmpty {
                return item.profile.nickname
            }
            return "\(item.profile.nickname) · \(meta)"
        }()
        return BuddyPersonBrowseContextActions(
            contactTitle: contactTitle,
            onContact: onContact,
            onBook: (BuddyPersonBrowseChrome.isPaid(item) && item.inviteEnabled) ? onBook : nil,
            shareText: share
        )
    }
}

extension View {
    /// 浏览卡长按菜单：联系、可约时预约、系统分享。
    func buddyPersonBrowseContextMenu(_ actions: BuddyPersonBrowseContextActions) -> some View {
        contextMenu {
            Button(actions.contactTitle, systemImage: "bubble.left.and.bubble.right") {
                actions.onContact()
            }
            if let onBook = actions.onBook {
                Button(BuddyDetailCopy.quickBook, systemImage: "calendar") {
                    onBook()
                }
            }
            ShareLink(item: actions.shareText) {
                Label(BuddyBrowseCopy.ContextMenu.share, systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    func buddyPersonBrowseContextMenu(_ actions: BuddyPersonBrowseContextActions?) -> some View {
        if let actions {
            buddyPersonBrowseContextMenu(actions)
        } else {
            self
        }
    }
}
