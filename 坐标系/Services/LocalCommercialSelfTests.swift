//
//  LocalCommercialSelfTests.swift
//  坐标系
//

#if DEBUG
import Foundation

@MainActor
enum LocalCommercialSelfTests {
    static func runCriticalChecks() {
        // 历史启动自检曾写入共享钱包；先清掉再跑，避免「最近交易」堆陪玩阿凯扣款
        WalletStore.shared.purgeDebugSelfTestBookingCharges()

        let results = [
            checkGroupChatDedupByActivityID(),
            checkBookingStatusMachine(),
            checkWaitlist(),
            checkSensitiveFilter()
        ]
        if results.contains(false) {
            print("LocalCommercialSelfTests: one or more checks failed")
        }
    }

    @discardableResult
    private static func checkGroupChatDedupByActivityID() -> Bool {
        let repo = InMemoryMessagesRepository(
            snapshot: MessagesSnapshot(conversations: [], threads: [:])
        )
        let messages = MessagesModel(snapshot: repo.snapshot, repository: repo)
        let activity = Activity(
            id: UUID(),
            title: "同名活动 A",
            category: .outdoorSports,
            location: "测试",
            date: .now.addingTimeInterval(3600),
            capacity: 8,
            joined: 1,
            hostName: "测",
            summary: "summary",
            fee: "免费",
            tags: []
        )
        let first = messages.startGroupChat(
            for: activity,
            role: .host,
            memberName: "测",
            announceMembership: false
        )
        let second = messages.startGroupChat(
            for: activity,
            role: .participant,
            memberName: "报名者",
            announceMembership: false
        )
        guard first?.id == second?.id else {
            print("LocalCommercialSelfTests: 群聊应按 activity.id 去重")
            return false
        }
        guard first?.relatedActivityID == activity.id, first?.ownerName == activity.hostName else {
            print("LocalCommercialSelfTests: 群聊应关联 activity 且群主为发起人")
            return false
        }
        guard messages.messages(for: first!.id).first?.isSystem == true,
              messages.messages(for: first!.id).first?.text == MessagesCopy.groupCreated
        else {
            print("LocalCommercialSelfTests: 主办建群应为系统小字「你创建了群聊」")
            return false
        }

        let other = Activity(
            id: UUID(),
            title: "报名局",
            category: .food,
            location: "测试",
            date: .now.addingTimeInterval(7200),
            capacity: 4,
            joined: 1,
            hostName: "别人",
            summary: "s",
            fee: "免费",
            tags: []
        )
        let joined = messages.startGroupChat(
            for: other,
            role: .participant,
            memberName: "林屿",
            announceMembership: true
        )
        guard let joinTip = messages.messages(for: joined!.id).first,
              joinTip.isSystem,
              joinTip.text == MessagesCopy.memberJoined("林屿")
        else {
            print("LocalCommercialSelfTests: 报名进群应为系统小字「XX加入了群聊」")
            return false
        }

        _ = messages.startGroupChat(
            for: other,
            role: .participant,
            memberName: "新同学",
            announceMembership: true
        )
        let visibleToMember = messages.visibleMessages(
            for: joined!.id,
            viewerName: "林屿",
            ownerName: "别人"
        )
        messages.leaveGroupChat(
            activityID: other.id,
            leaverName: "林屿",
            currentUserIsOwner: false
        )
        guard messages.conversations.contains(where: { $0.id == joined?.id }) == false else {
            print("LocalCommercialSelfTests: 成员退群后应从自己列表移除")
            return false
        }

        // 群主侧：建群后模拟成员退出，仅群主可见退群小字
        let hostGroup = messages.startGroupChat(
            for: activity,
            role: .host,
            memberName: "测",
            announceMembership: false
        )!
        messages.leaveGroupChat(
            activityID: activity.id,
            leaverName: "过客",
            currentUserIsOwner: true
        )
        let hostVisible = messages.visibleMessages(
            for: hostGroup.id,
            viewerName: "测",
            ownerName: "测"
        )
        let memberVisible = messages.visibleMessages(
            for: hostGroup.id,
            viewerName: "路人",
            ownerName: "测"
        )
        guard hostVisible.contains(where: { $0.text == MessagesCopy.memberLeft("过客") }) else {
            print("LocalCommercialSelfTests: 群主应看到退群小字")
            return false
        }
        guard !memberVisible.contains(where: { $0.text == MessagesCopy.memberLeft("过客") }) else {
            print("LocalCommercialSelfTests: 非群主不应看到退群小字")
            return false
        }
        _ = visibleToMember

        let chat = messages.startChat(with: "测试搭子", greeting: "第一次", deliverGreeting: true)
        _ = messages.startChat(with: "测试搭子", greeting: "第二次问候", deliverGreeting: true)
        let thread = messages.messages(for: chat!.id)
        guard thread.last?.text == "第二次问候" else {
            print("LocalCommercialSelfTests: 再次打招呼应发送新问候")
            return false
        }
        return true
    }

    @discardableResult
    private static func checkBookingStatusMachine() -> Bool {
        let repo = InMemoryBuddiesRepository(
            snapshot: BuddiesSnapshot(inviteRecords: [], bookingRecords: [], joinedCircleNames: [])
        )
        let buddies = BuddiesModel(snapshot: repo.snapshot, repository: repo)
        guard let companion = SampleData.paidCompanions.first else { return true }
        guard let record = buddies.recordBooking(
            companion: companion,
            scheduledAt: .now.addingTimeInterval(86400),
            hours: 2
        ) else {
            print("LocalCommercialSelfTests: 创建预约失败")
            return false
        }
        guard record.status == .pendingConfirm else { return false }
        buddies.acceptBooking(record.id)
        guard buddies.bookingRecords.first?.status == .awaitingPayment else { return false }
        // 自检走 Apple Pay，避免依赖演示余额；结束后从共享账本移除，避免污染「最近交易」
        let bookingID = record.id
        guard buddies.confirmPayment(bookingID, method: .applePay) == .success else {
            print("LocalCommercialSelfTests: 预约支付失败")
            return false
        }
        guard buddies.bookingRecords.first?.status == .paid else {
            WalletStore.shared.removeEntries(relatedTo: bookingID)
            return false
        }
        buddies.completeBooking(bookingID)
        let ok = buddies.bookingRecords.first?.status == .completed
        WalletStore.shared.removeEntries(relatedTo: bookingID)
        return ok
    }

    @discardableResult
    private static func checkWaitlist() -> Bool {
        let activity = Activity(
            id: UUID(),
            title: "满员局",
            category: .interestSocial,
            location: "测试",
            date: .now.addingTimeInterval(7200),
            capacity: 1,
            joined: 1,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: []
        )
        let repo = InMemoryActivitiesRepository(
            snapshot: ActivitiesSnapshot(
                activities: [activity],
                joinedIDs: [],
                favoriteIDs: [],
                waitlistIDs: []
            )
        )
        let model = ActivitiesModel(currentUserName: "测试用户", repository: repo)
        guard model.activities[0].isFull else { return false }
        guard model.toggleWaitlist(activity.id) else { return false }
        guard model.isWaitlisted(activity.id) else { return false }
        model.activities[0].joined = 0
        model.activities[0].capacity = 1
        guard model.promoteFromWaitlist(activity.id) else { return false }
        guard model.isJoined(activity.id) else { return false }
        guard !model.isWaitlisted(activity.id) else { return false }
        return true
    }

    @discardableResult
    private static func checkSensitiveFilter() -> Bool {
        guard ContentModeration.containsSensitive("正常内容") == nil else { return false }
        guard ContentModeration.containsSensitive("涉嫌诈骗链接") != nil else { return false }
        return true
    }
}
#endif
