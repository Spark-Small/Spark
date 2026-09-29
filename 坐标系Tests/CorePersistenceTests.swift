//
//  CorePersistenceTests.swift
//  坐标系Tests
import CoordinateDomain
import XCTest
@testable import 坐标系

@MainActor
final class CorePersistenceTests: XCTestCase {
    func testRepositoryGenerationInvalidationDropsStaleWrites() async {
        let repo = InMemoryProfileRepository(snapshot: .seed)
        let staleGeneration = repo.currentPersistenceGeneration()
        repo.invalidatePendingWrites()

        do {
            try await repo.replaceAsync(with: .seed, generation: staleGeneration)
            XCTFail("stale write should be cancelled")
        } catch is CancellationError {
            XCTAssertEqual(repo.snapshot.user, ProfileSnapshot.seed.user)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testMessagesConversationCallbackFiresForDirectChatLifecycle() {
        let repo = InMemoryMessagesRepository(
            snapshot: MessagesSnapshot(conversations: [], threads: [:])
        )
        let deps = AppDependencies.inMemoryForTests()
        let messages = deps.makeMessagesModel(snapshot: repo.snapshot, repository: repo)
        var callbackCount = 0
        messages.onConversationsChanged = {
            callbackCount += 1
        }

        let convo = messages.startChat(with: "阿川", greeting: "hi", deliverGreeting: false)
        XCTAssertNotNil(convo)
        XCTAssertEqual(callbackCount, 1)

        if let id = convo?.id {
            messages.delete(id)
        }
        XCTAssertEqual(callbackCount, 2)
    }

    func testBuddiesRecordsCallbackFiresForInviteAndBookingMutations() {
        let repo = InMemoryBuddiesRepository(
            snapshot: BuddiesSnapshot(inviteRecords: [], bookingRecords: [], joinedCircleNames: [])
        )
        let deps = AppDependencies.inMemoryForTests()
        let buddies = deps.makeBuddiesModel(snapshot: repo.snapshot, repository: repo)
        var callbackCount = 0
        buddies.onRecordsChanged = {
            callbackCount += 1
        }

        let activity = Activity(
            id: UUID(),
            title: "测试邀约局",
            category: .outdoorSports,
            location: "成都",
            date: .now.addingTimeInterval(7200),
            capacity: 10,
            joined: 2,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: ["测"]
        )
        _ = buddies.recordInvite(nickname: "阿川", activity: activity)
        XCTAssertEqual(callbackCount, 1)
        if let inviteID = buddies.inviteRecords.first?.id {
            buddies.acceptInvite(inviteID)
        }
        XCTAssertEqual(callbackCount, 2)

        guard let companion = SampleData.paidCompanions.first else {
            return XCTFail("缺少陪玩样本")
        }
        _ = buddies.recordBooking(
            companion: companion,
            scheduledAt: .now.addingTimeInterval(86400),
            hours: 1
        )
        XCTAssertEqual(callbackCount, 3)
    }

    func testGroupChatDedupUsesActivityID() {
        let repo = InMemoryMessagesRepository(
            snapshot: MessagesSnapshot(conversations: [], threads: [:])
        )
        let deps = AppDependencies.inMemoryForTests()
        let messages = deps.makeMessagesModel(snapshot: repo.snapshot, repository: repo)
        let activity = Activity(
            id: UUID(),
            title: "同名",
            category: .outdoorSports,
            location: "上海",
            date: .now.addingTimeInterval(7200),
            capacity: 10,
            joined: 2,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: ["测"]
        )
        let a = messages.startGroupChat(for: activity)
        let b = messages.startGroupChat(for: activity)
        XCTAssertEqual(a?.id, b?.id)
        XCTAssertEqual(a?.relatedActivityID, activity.id)
    }

    func testBookingPaymentFlow() {
        let repo = InMemoryBuddiesRepository(
            snapshot: BuddiesSnapshot(inviteRecords: [], bookingRecords: [], joinedCircleNames: [])
        )
        let deps = AppDependencies.inMemoryForTests()
        let buddies = deps.makeBuddiesModel(snapshot: repo.snapshot, repository: repo)
        guard let companion = SampleData.paidCompanions.first else {
            return XCTFail("缺少陪玩样本")
        }
        let record = buddies.recordBooking(
            companion: companion,
            scheduledAt: .now.addingTimeInterval(86400),
            hours: 1
        )
        XCTAssertEqual(record?.status, .pendingConfirm)
        guard let id = record?.id else { return XCTFail("无订单") }
        buddies.acceptBooking(id)
        XCTAssertEqual(buddies.bookingRecords.first?.status, .awaitingPayment)
        XCTAssertNotNil(buddies.bookingRecords.first?.paymentDueAt)
        XCTAssertNil(buddies.pendingPaymentBooking)
        XCTAssertEqual(buddies.pendingAwaitingPaymentReviewID, id)
        buddies.beginPayment(id)
        XCTAssertEqual(buddies.pendingPaymentBooking?.id, id)
        XCTAssertNil(buddies.pendingAwaitingPaymentReviewID)
        buddies.confirmPayment(id)
        XCTAssertEqual(buddies.bookingRecords.first?.status, .paid)
    }

    func testInviteStatusFlow() {
        let repo = InMemoryBuddiesRepository(
            snapshot: BuddiesSnapshot(inviteRecords: [], bookingRecords: [], joinedCircleNames: [])
        )
        let deps = AppDependencies.inMemoryForTests()
        let buddies = deps.makeBuddiesModel(snapshot: repo.snapshot, repository: repo)
        let activity = Activity(
            id: UUID(),
            title: "测试邀约局",
            category: .outdoorSports,
            location: "成都",
            date: .now.addingTimeInterval(7200),
            capacity: 10,
            joined: 2,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: ["测"]
        )
        let record = buddies.recordInvite(nickname: "阿川", activity: activity)
        XCTAssertEqual(record.status, .pending)
        buddies.acceptInvite(record.id)
        XCTAssertEqual(buddies.inviteRecords.first?.status, .accepted)
    }

    func testWaitlistWhenFull() {
        let activity = Activity(
            id: UUID(),
            title: "满",
            category: .food,
            location: "L",
            date: .now.addingTimeInterval(3600),
            capacity: 1,
            joined: 1,
            hostName: "H",
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
        let deps = AppDependencies.inMemoryForTests()
        let model = deps.makeActivitiesModel(currentUserName: "Tester", repository: repo)
        XCTAssertTrue(model.activities[0].isFull)
        XCTAssertTrue(model.toggleWaitlist(activity.id))
        XCTAssertTrue(model.isWaitlisted(activity.id))
    }

    func testWaitlistPromotionWhenSpotOpens() {
        let activityID = UUID()
        let activity = Activity(
            id: activityID,
            title: "满员局",
            category: .interestSocial,
            location: "测试",
            date: .now.addingTimeInterval(7200),
            capacity: 2,
            joined: 2,
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
                waitlistIDs: [activityID]
            )
        )
        let deps = AppDependencies.inMemoryForTests()
        let model = deps.makeActivitiesModel(currentUserName: "测试用户", repository: repo)
        XCTAssertTrue(model.isWaitlisted(activityID))

        model.activities[0].joined = 1
        XCTAssertTrue(model.promoteFromWaitlist(activityID))
        XCTAssertTrue(model.isJoined(activityID))
        XCTAssertFalse(model.isWaitlisted(activityID))
    }

    func testLifecyclePhase() {
        let upcoming = Activity(
            id: UUID(),
            title: "未开始",
            category: .outdoorSports,
            location: "上海",
            date: .now.addingTimeInterval(7200),
            capacity: 10,
            joined: 1,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: []
        )
        XCTAssertEqual(upcoming.lifecyclePhase, .upcoming)

        let ended = Activity(
            id: UUID(),
            title: "已结束",
            category: .outdoorSports,
            location: "上海",
            date: .now.addingTimeInterval(-ActivityLifecycle.ongoingGrace - 60),
            capacity: 10,
            joined: 1,
            hostName: "Host",
            summary: "s",
            fee: "免费",
            tags: []
        )
        XCTAssertEqual(ended.lifecyclePhase, .ended)
        XCTAssertFalse(ended.isJoinable)
    }

    func testModerationTicketStatusMachine() {
        let repos = AppRepositories.inMemoryForTests(
            profile: ProfileSnapshot(
                user: SampleData.currentUser,
                hasCompletedOnboarding: true,
                blockedUserNames: [],
                moderationTickets: []
            )
        )
        let app = AppDependencies.inMemoryForTests(repositories: repos).makeAppModel()
        app.addModerationTicket(
            postID: UUID(),
            title: "测试动态",
            reason: "垃圾广告",
            targetKind: .communityPost
        )
        guard let id = app.moderationTickets.first?.id else {
            return XCTFail("无工单")
        }
        XCTAssertEqual(app.moderationTickets.first?.status, .received)
        app.advanceModerationTicket(id)
        XCTAssertEqual(app.moderationTickets.first?.status, .reviewing)
        app.advanceModerationTicket(id)
        XCTAssertEqual(app.moderationTickets.first?.status, .resolved)
    }

    func testBookingCompleteRequiresActiveStatus() {
        let repo = InMemoryBuddiesRepository(
            snapshot: BuddiesSnapshot(inviteRecords: [], bookingRecords: [], joinedCircleNames: [])
        )
        let deps = AppDependencies.inMemoryForTests()
        let buddies = deps.makeBuddiesModel(snapshot: repo.snapshot, repository: repo)
        guard let companion = SampleData.paidCompanions.first else {
            return XCTFail("缺少陪玩样本")
        }
        guard let record = buddies.recordBooking(
            companion: companion,
            scheduledAt: .now.addingTimeInterval(86400),
            hours: 1
        ) else {
            return XCTFail("创建预约失败")
        }
        buddies.completeBooking(record.id)
        XCTAssertEqual(buddies.bookingRecords.first?.status, .pendingConfirm)
        buddies.acceptBooking(record.id)
        buddies.confirmPayment(record.id)
        buddies.markInProgress(record.id)
        XCTAssertEqual(buddies.bookingRecords.first?.status, .inProgress)
        buddies.completeBooking(record.id)
        XCTAssertEqual(buddies.bookingRecords.first?.status, .completed)
    }

    func testMessagesSnapshotRepairNormalizesMappingsAndDropsOrphans() {
        let directID = UUID()
        let groupID = UUID()
        let orphanID = UUID()
        let requestID = UUID()

        let direct = ChatConversation(
            id: directID,
            title: "阿川",
            subtitle: "私聊",
            lastMessage: "hi",
            updatedAt: .now,
            unreadCount: 0,
            kind: .direct
        )
        let group = ChatConversation(
            id: groupID,
            title: "活动群",
            subtitle: "群聊",
            lastMessage: "welcome",
            updatedAt: .now,
            unreadCount: 0,
            kind: .group
        )
        let message = ChatMessage(
            id: UUID(),
            sender: "阿川",
            text: "hello",
            sentAt: .now,
            isMe: false,
            messageKind: .text
        )
        let snapshot = MessagesSnapshot(
            conversations: [direct, group],
            threads: [
                directID.uuidString: [message],
                orphanID.uuidString: [message]
            ],
            friendRequests: [
                FriendRequest(id: requestID, fromName: "A", message: "old", createdAt: .now.addingTimeInterval(-60), status: .pending),
                FriendRequest(id: requestID, fromName: "A", message: "new", createdAt: .now, status: .accepted)
            ],
            friendRemarks: ["  AChuan  ": "  老搭子  ", "   ": "ignored"],
            friendGroups: [" AChuan ": "  骑行  ", "empty": "   "],
            groupMembers: [
                groupID.uuidString: [],
                orphanID.uuidString: []
            ],
            transferRecords: [
                TransferRecord(conversationID: directID, amount: 20, senderName: "我", recipientName: "阿川", messageID: UUID()),
                TransferRecord(conversationID: orphanID, amount: 20, senderName: "我", recipientName: "路人", messageID: UUID())
            ],
            callRecords: [
                CallSessionRecord(conversationID: groupID, kind: .voice),
                CallSessionRecord(conversationID: orphanID, kind: .video)
            ]
        )

        let repaired = MessagesSnapshotCatalog.repair(from: snapshot)

        XCTAssertNotNil(repaired.threads[directID.uuidString])
        XCTAssertNotNil(repaired.threads[groupID.uuidString])
        XCTAssertNil(repaired.threads[orphanID.uuidString])
        XCTAssertEqual(repaired.threads[groupID.uuidString]?.count, 0)
        XCTAssertEqual(repaired.friendRequests.count, 1)
        XCTAssertEqual(repaired.friendRequests.first?.message, "new")
        XCTAssertEqual(repaired.friendRemarks["achuan"], "老搭子")
        XCTAssertNil(repaired.friendRemarks["  AChuan  "])
        XCTAssertEqual(repaired.friendGroups["achuan"], "骑行")
        XCTAssertEqual(Set(repaired.groupMembers.keys), [groupID.uuidString])
        XCTAssertEqual(repaired.transferRecords.map(\.conversationID), [directID])
        XCTAssertEqual(repaired.callRecords.map(\.conversationID), [groupID])
    }

    func testCommunitySnapshotRepairFiltersInvalidReferences() {
        let postID = UUID()
        let invalidPostID = UUID()
        let rootCommentID = UUID()
        let replyCommentID = UUID()
        let invalidCommentID = UUID()

        let post = CommunityPost(
            id: postID,
            author: "作者",
            title: "标题",
            body: "正文",
            tags: ["骑行"],
            likeCount: 0,
            commentCount: 99,
            repostCount: 0,
            shareCount: 0,
            postedAt: .now,
            isPinned: false,
            photoSeeds: [1],
            photoHue: 0.2,
            comments: [
                CommunityComment(id: rootCommentID, author: "A", text: "root", postedAt: .now),
                CommunityComment(
                    id: replyCommentID,
                    author: "B",
                    text: "reply",
                    postedAt: .now,
                    parentID: invalidCommentID,
                    replyToAuthor: "Ghost",
                    likeCount: 0
                )
            ],
            likerNames: ["阿川", "阿川", "Mia"],
            reportCount: -3
        )
        let snapshot = CommunitySnapshot(
            posts: [post],
            likedIDs: [postID, invalidPostID],
            repostedIDs: [invalidPostID],
            bookmarkedIDs: [postID, invalidPostID],
            bookmarkCollections: [
                postID.uuidString: "  精选  ",
                invalidPostID.uuidString: "无效",
                "not-a-uuid": "坏数据"
            ],
            reportedIDs: [invalidPostID],
            likedCommentIDs: [rootCommentID, invalidCommentID]
        )

        let repaired = CommunitySnapshotCatalog.repair(from: snapshot)

        XCTAssertEqual(repaired.posts.first?.commentCount, 2)
        XCTAssertEqual(repaired.posts.first?.likeCount, 2)
        XCTAssertEqual(repaired.posts.first?.likerNames, ["阿川", "Mia"])
        XCTAssertEqual(repaired.posts.first?.comments.last?.parentID, nil)
        XCTAssertEqual(repaired.posts.first?.comments.last?.replyToAuthor, nil)
        XCTAssertEqual(repaired.posts.first?.reportCount, 0)
        XCTAssertEqual(repaired.likedIDs, [postID])
        XCTAssertTrue(repaired.repostedIDs.isEmpty)
        XCTAssertEqual(repaired.bookmarkedIDs, [postID])
        XCTAssertEqual(repaired.bookmarkCollections, [postID.uuidString: "精选"])
        XCTAssertTrue(repaired.reportedIDs.isEmpty)
        XCTAssertEqual(repaired.likedCommentIDs, [rootCommentID])
    }
}
