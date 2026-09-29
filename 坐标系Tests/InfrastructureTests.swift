//
//  InfrastructureTests.swift
//  坐标系Tests
//

import CoordinateData
import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateNetworking
import XCTest
@testable import 坐标系

@MainActor
final class InfrastructureTests: XCTestCase {
    func testAppRouterClearPendingIntents() {
        let router = AppRouter()
        router.pendingActivityID = UUID()
        router.pendingActivityFollowUp = .journeyFeedback
        router.pendingActivityJourneyFollowUp = .journeyRecap
        router.pendingConversationID = UUID()
        router.pendingBookingID = UUID()
        router.pendingProfileRoute = .wallet
        router.pendingBuddiesRoute = .clubDiscover

        router.clearPendingIntents()

        XCTAssertNil(router.pendingActivityID)
        XCTAssertEqual(router.pendingActivityFollowUp, .none)
        XCTAssertEqual(router.pendingActivityJourneyFollowUp, .none)
        XCTAssertNil(router.pendingConversationID)
        XCTAssertNil(router.pendingBookingID)
        XCTAssertNil(router.pendingProfileRoute)
        XCTAssertNil(router.pendingBuddiesRoute)
    }

    func testAppRouterApplyBuddiesClubDiscoverDeepLink() {
        let router = AppRouter()
        var tab: AppTab = .activities

        router.apply(.buddies(.clubDiscover), selectedTab: &tab)

        XCTAssertEqual(tab, .buddies)
        XCTAssertEqual(router.pendingBuddiesRoute, .clubDiscover)
    }

    func testAppModelOpenClubDiscover() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()

        app.openClubDiscover()

        XCTAssertEqual(app.selectedTab, .buddies)
        XCTAssertEqual(app.pendingBuddiesRoute, .clubDiscover)
    }

    func testAppRouterApplyActivityRecapDeepLink() {
        let router = AppRouter()
        var tab: AppTab = .messages
        let activityID = UUID()

        router.apply(.activity(activityID, followUp: .journeyFeedback), selectedTab: &tab)

        XCTAssertEqual(tab, .activities)
        XCTAssertEqual(router.pendingActivityID, activityID)
        XCTAssertEqual(router.pendingActivityFollowUp, .journeyFeedback)
    }

    func testNotificationDeepLinkParsesActivityRecap() {
        let activityID = UUID()
        let link = NotificationDeepLink.parse(
            userInfo: [
                "activityID": activityID.uuidString,
                "kind": "activity-recap"
            ],
            identifier: "activity-recap-\(activityID.uuidString)"
        )

        XCTAssertEqual(link, .activity(activityID, followUp: .journeyFeedback))
    }

    func testNotificationDeepLinkParsesActivityReminder() {
        let activityID = UUID()
        let link = NotificationDeepLink.parse(
            userInfo: [
                "activityID": activityID.uuidString,
                "kind": "activity-reminder"
            ],
            identifier: "activity-\(activityID.uuidString)"
        )

        XCTAssertEqual(link, .activity(activityID, followUp: .openJourney))
    }

    func testNotificationDeepLinkParsesWaitlistSpot() {
        let activityID = UUID()
        let link = NotificationDeepLink.parse(
            userInfo: [
                "activityID": activityID.uuidString,
                "kind": "waitlist-spot"
            ],
            identifier: "waitlist-spot-\(activityID.uuidString)"
        )

        XCTAssertEqual(link, .activity(activityID, followUp: .none))
    }

    func testWelcomeLandingChipCandidatesStayWithinBrowseChipOrder() {
        let order = Set(ActivityQuickFilter.browseChipOrder)
        for filter in [ActivityQuickFilter.today, .weekend, .free] {
            XCTAssertTrue(order.contains(filter))
        }
        XCTAssertFalse(order.contains(.available))
    }

    func testNextUpBannerShowsForEndedUnrecappedActivity() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()
        guard let activityID = app.activities.activities.first(where: { !app.activities.isHost($0) })?.id else {
            return XCTFail("缺少可参加的活动样本")
        }
        _ = app.activities.toggleJoin(activityID)
        guard let index = app.activities.activities.firstIndex(where: { $0.id == activityID }) else {
            return XCTFail("缺少活动索引")
        }
        app.activities.activities[index].date = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: .now
        ) ?? .now.addingTimeInterval(-86_400)

        let summary = ActivityNextUpPresentation.summary(
            for: app.activities,
            hasSeenWelcomeGuide: true
        )
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.phase, .ended)
        XCTAssertEqual(summary?.activity.id, activityID)
    }

    func testProductLifecycleTabVisitCount() {
        let store = ProductLifecycleStore()
        store.resetAll()
        store.recordTabVisit(.activities)
        store.recordTabVisit(.activities)
        store.recordTabVisit(.community)
        XCTAssertEqual(store.tabVisitCount(.activities, withinDays: 7), 2)
        XCTAssertEqual(store.tabVisitCount(.community, withinDays: 7), 1)
        XCTAssertEqual(store.tabVisitCount(.messages, withinDays: 7), 0)
    }

    func testAppRouterApplyActivityDeepLink() {
        let router = AppRouter()
        var tab: AppTab = .messages
        let activityID = UUID()

        router.apply(.activity(activityID), selectedTab: &tab)

        XCTAssertEqual(tab, .activities)
        XCTAssertEqual(router.pendingActivityID, activityID)
    }

    func testAppModelOpenActivitySetsPendingIntent() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()
        let activityID = UUID()

        app.openActivity(activityID)

        XCTAssertEqual(app.selectedTab, .activities)
        XCTAssertEqual(app.pendingActivityID, activityID)
    }

    func testWelcomeGuideFinishIsIdempotent() {
        let defaults = UserDefaults.standard
        let key = WelcomeGuideStore.storageKey
        let prior = defaults.bool(forKey: key)
        defer { defaults.set(prior, forKey: key) }
        defaults.removeObject(forKey: key)

        let repos = AppRepositories.inMemoryForTests(
            profile: ProfileSnapshot(
                user: SampleData.currentUser,
                hasCompletedOnboarding: false,
                blockedUserNames: [],
                moderationTickets: []
            )
        )
        let app = AppDependencies.inMemoryForTests(repositories: repos).makeAppModel()

        app.welcomeGuide.finish(app: app)
        XCTAssertTrue(app.welcomeGuide.hasSeenGuide)
        XCTAssertTrue(app.hasCompletedWelcomeBootstrap)

        app.welcomeGuide.finish(app: app)
        XCTAssertTrue(app.hasCompletedWelcomeBootstrap)
    }

    func testWelcomeLandingPrefersTodayWhenAvailable() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()
        let message = app.activities.applyWelcomeLanding(for: .findActivity)
        XCTAssertNotNil(message)
        XCTAssertTrue(
            app.activities.quickFilters.contains(.today)
                || app.activities.quickFilters.contains(.weekend)
                || app.activities.quickFilters.contains(.free)
                || message == AppWelcomeGuideCopy.findActivityConfirmedGeneric
        )
    }

    func testWelcomeLandingMeetPeopleAppliesSocialPage() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()
        let defaults = UserDefaults.standard
        let key = WelcomeGuideStore.storageKey
        let prior = defaults.bool(forKey: key)
        defer { defaults.set(prior, forKey: key) }
        defaults.removeObject(forKey: key)

        app.welcomeGuide.finish(app: app, intent: .meetPeople)

        XCTAssertEqual(app.selectedTab, .buddies)
        XCTAssertEqual(app.buddies.filter.kind, .free)
        XCTAssertTrue(app.buddies.pendingShowCircleDiscover)
    }

    func testNextUpBannerHiddenBeforeWelcomeGuide() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()
        guard let activityID = app.activities.activities.first(where: { !app.activities.isHost($0) })?.id else {
            return XCTFail("缺少可参加的活动样本")
        }
        _ = app.activities.toggleJoin(activityID)

        let summary = ActivityNextUpPresentation.summary(
            for: app.activities,
            hasSeenWelcomeGuide: false
        )
        XCTAssertNil(summary)
    }

    func testNextUpBannerHiddenWhenNextActivityBeyondSevenDays() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()
        guard let activityID = app.activities.activities.first(where: { !app.activities.isHost($0) })?.id else {
            return XCTFail("缺少活动样本")
        }
        _ = app.activities.toggleJoin(activityID)
        guard let index = app.activities.activities.firstIndex(where: { $0.id == activityID }) else {
            return XCTFail("缺少活动索引")
        }
        app.activities.activities[index].date = Calendar.current.date(
            byAdding: .day,
            value: 10,
            to: .now
        ) ?? .now.addingTimeInterval(864_000)

        let summary = ActivityNextUpPresentation.summary(
            for: app.activities,
            hasSeenWelcomeGuide: true
        )
        XCTAssertNil(summary)
    }

    func testNextUpBannerShowsWithinSevenDays() {
        let app = AppDependencies.inMemoryForTests().makeAppModel()
        guard let activityID = app.activities.activities.first(where: { !app.activities.isHost($0) })?.id else {
            return XCTFail("缺少可参加的活动样本")
        }
        _ = app.activities.toggleJoin(activityID)
        guard let index = app.activities.activities.firstIndex(where: { $0.id == activityID }) else {
            return XCTFail("缺少活动索引")
        }
        app.activities.activities[index].date = Calendar.current.date(
            byAdding: .day,
            value: 2,
            to: .now
        ) ?? .now.addingTimeInterval(172_800)

        let summary = ActivityNextUpPresentation.summary(
            for: app.activities,
            hasSeenWelcomeGuide: true
        )
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.activity.id, activityID)
    }

    func testCredentialArtSceneMapsEntertainmentCategory() {
        XCTAssertEqual(CredentialArtScene.forActivityCategory(.entertainment), .event)
        XCTAssertEqual(CredentialArtScene.forActivityCategory(.food), .dining)
    }

    func testCredentialArtStripRendererProducesImage() {
        let size = PassTemplateResources.pixelSize(kind: .eventStrip, scale: .x1)
        let image = CredentialArtStripRenderer.walletStripImage(for: .entertainment, pixelSize: size)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    }

    func testEventStripPNGWithCredentialArtCover() {
        let stripSurface = PassTemplateResources.uiStripSurfaceColor(for: ActivityCategory.entertainment.rawValue)
        let size = PassTemplateResources.pixelSize(kind: .eventStrip, scale: .x1)
        let cover = CredentialArtStripRenderer.walletStripImage(for: .entertainment, pixelSize: size)
        let files = PassTemplateResources.eventStripPNG(
            stripColor: stripSurface,
            cover: cover,
            usesCredentialArt: true
        )
        XCTAssertNotNil(files["strip.png"])
        XCTAssertNotNil(files["strip@2x.png"])
    }

    func testProductLifecycleEligibleTipsReturnsAllMatches() {
        let store = ProductLifecycleStore()
        store.resetAll()
        store.recordOpen()
        store.recordOpen()
        store.recordOpen()

        let tips = store.eligibleTips(isGuest: true, profileComplete: false, hasOrders: false)
        XCTAssertGreaterThanOrEqual(tips.count, 2)
        XCTAssertEqual(store.activeTips(isGuest: true, profileComplete: false, hasOrders: false).count, 1)
    }

    func testShouldMergeCommunityWhenSevenDayZeroOpens() {
        let store = ProductLifecycleStore()
        store.resetAll()
        for _ in 0..<4 {
            store.recordOpen()
        }
        store.recordTabVisit(.activities)
        store.recordTabVisit(.activities)

        XCTAssertFalse(store.shouldMergeCommunityIntoActivitiesTab)

        let merged = ProductLifecycleStore()
        merged.resetAll()
        let install = Calendar.current.date(byAdding: .day, value: -8, to: .now) ?? .now
        UserDefaults.standard.set(install, forKey: "lifecycle.installAt")
        let reloaded = ProductLifecycleStore()
        for _ in 0..<3 {
            reloaded.recordOpen()
        }
        reloaded.recordTabVisit(.activities)

        XCTAssertTrue(reloaded.shouldMergeCommunityIntoActivitiesTab)
        XCTAssertEqual(reloaded.tabVisitCount(.community, withinDays: 7), 0)
    }

    func testInMemoryCommunityRepositoryRoundTrip() {
        let repo = InMemoryCommunityRepository(snapshot: .emptySeed)
        var snapshot = repo.load()
        snapshot.likedIDs = [snapshot.posts.first!.id]

        repo.save(snapshot)

        XCTAssertEqual(repo.load().likedIDs, snapshot.likedIDs)
    }

    func testInMemoryMessagesRepositoryRoundTrip() {
        let repo = InMemoryMessagesRepository(snapshot: .seed)
        var snapshot = repo.load()
        snapshot.friendRemarks["alice"] = "阿丽"

        repo.save(snapshot)

        XCTAssertEqual(repo.load().friendRemarks["alice"], "阿丽")
    }

    func testInMemoryBuddiesRepositoryRoundTrip() {
        let repo = InMemoryBuddiesRepository(
            snapshot: BuddiesSnapshot(inviteRecords: [], bookingRecords: [], joinedCircleNames: [])
        )
        var snapshot = repo.load()
        let circleID = SampleData.interestCircles[0].id
        snapshot.joinedCircleIDs = [circleID]
        snapshot.joinedCircleNames = [SampleData.interestCircles[0].name]

        repo.save(snapshot)

        let loaded = repo.load()
        XCTAssertEqual(loaded.joinedCircleIDs, [circleID])
        XCTAssertEqual(loaded.joinedCircleNames, ["黄浦夜骑群"])
    }

    func testYouthModeStorePersistsToggle() {
        let store = YouthModeStore.shared
        let prior = store.isEnabled
        defer { store.isEnabled = prior }

        store.isEnabled = true
        XCTAssertTrue(YouthModePreference.isEnabled)

        store.isEnabled = false
        XCTAssertFalse(YouthModePreference.isEnabled)
    }

    func testLegalConsentStoreAcceptAndReset() {
        let store = LegalConsentStore.shared
        store.reset()
        defer { store.reset() }

        XCTAssertTrue(store.needsConsent)
        store.accept()
        XCTAssertFalse(store.needsConsent)
        XCTAssertTrue(LegalConsentPreference.isAccepted)
    }

    func testMembershipAdImpressionStoreIncrements() async throws {
        let store = MembershipAdImpressionStore.shared
        let priorViews = store.viewCount
        let priorTaps = store.tapCount
        defer { store.reset() }

        try await store.handleView(isActive: false)
        try await store.handleTap(isActive: false)
        XCTAssertEqual(store.viewCount, priorViews + 1)
        XCTAssertEqual(store.tapCount, priorTaps + 1)
    }

    func testFeatureFlagsMigratesLegacyRemoteCatalogKey() {
        let defaults = UserDefaults.standard
        let legacyKey = "api.useRemoteCatalog"
        let newKey = "feature.useRemoteCatalog"
        let savedLegacy = defaults.object(forKey: legacyKey)
        let savedNew = defaults.object(forKey: newKey)

        defer {
            if let savedLegacy {
                defaults.set(savedLegacy, forKey: legacyKey)
            } else {
                defaults.removeObject(forKey: legacyKey)
            }
            if let savedNew {
                defaults.set(savedNew, forKey: newKey)
            } else {
                defaults.removeObject(forKey: newKey)
            }
        }

        defaults.set(true, forKey: legacyKey)
        defaults.removeObject(forKey: newKey)

        FeatureFlags.migrateLegacyFlagsIfNeeded()

        XCTAssertTrue(FeatureFlags.useRemoteCatalog)
        XCTAssertNil(defaults.object(forKey: legacyKey))
    }

    func testAPIClientMapsHTTPError() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let baseURL = URL(string: "https://api.test.local/v1")!
        let client = APIClient(baseURL: baseURL, session: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await client.send(APIEndpoint<ActivitiesSnapshot>.activitiesCatalog)
            XCTFail("expected http error")
        } catch let error as APIError {
            XCTAssertEqual(error, .httpStatus(500))
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        MockURLProtocol.requestHandler = nil
    }

    func testAPIClientMapsDecodingError() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let baseURL = URL(string: "https://api.test.local/v1")!
        let client = APIClient(baseURL: baseURL, session: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("{".utf8))
        }

        do {
            _ = try await client.send(APIEndpoint<ActivitiesSnapshot>.activitiesCatalog)
            XCTFail("expected decoding error")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        MockURLProtocol.requestHandler = nil
    }

    func testActivityCalendarStoreRoundTrip() {
        let activityID = UUID()
        ActivityCalendarStore.setEventIdentifier("evt-1", for: activityID)
        XCTAssertEqual(ActivityCalendarStore.eventIdentifier(for: activityID), "evt-1")
        ActivityCalendarStore.clearEventIdentifier(for: activityID)
        XCTAssertNil(ActivityCalendarStore.eventIdentifier(for: activityID))
    }

    func testInMemoryEngagementRepositoryRoundTrip() {
        let repo = InMemoryEngagementRepository(snapshot: .seed)
        var snapshot = repo.load()
        snapshot.tagWeights["骑行"] = 5

        repo.save(snapshot)

        XCTAssertEqual(repo.load().tagWeights["骑行"], 5)
    }

    func testBookingCompanionSimulationRespectsFeatureFlag() {
        #if DEBUG
        let key = "feature.simulateBookingCompanionAcceptance"
        let defaults = UserDefaults.standard
        let prior = defaults.object(forKey: key)
        defer {
            if let prior {
                defaults.set(prior, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        FeatureFlags.setSimulateBookingCompanionAcceptance(false)

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
        guard let id = record?.id else { return XCTFail("无订单") }

        XCTAssertEqual(buddies.bookingRecords.first?.status, .pendingConfirm)
        buddies.simulateCompanionAcceptsIfNeeded()
        XCTAssertEqual(buddies.bookingRecords.first?.status, .pendingConfirm)

        buddies.acceptBooking(id)
        XCTAssertEqual(buddies.bookingRecords.first?.status, .awaitingPayment)
        #else
        throw XCTSkip("Feature flag override only available in DEBUG builds")
        #endif
    }

    func testRemoteBookingSubmitAndFetchRoundTrip() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let baseURL = URL(string: "https://api.test.local/v1")!
        let client = APIClient(baseURL: baseURL, session: session)
        let service = RemoteBookingSyncService(client: client)

        let bookingID = UUID()
        let acceptedAt = Date(timeIntervalSince1970: 1_700_100_000)
        let dueAt = acceptedAt.addingTimeInterval(86_400)
        let remoteRecord = BuddyBookingRecord(
            id: bookingID,
            companionNickname: "阿川",
            hours: 2,
            scheduledAt: acceptedAt.addingTimeInterval(7200),
            bookedAt: acceptedAt,
            priceText: "¥100",
            status: .awaitingPayment,
            acceptedAt: acceptedAt,
            paymentDueAt: dueAt
        )
        let remoteData = try JSONEncoder().encode(remoteRecord)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            if request.httpMethod == "POST", request.url?.path.contains("/buddies/bookings") == true {
                return (response, remoteData)
            }
            if request.httpMethod == "GET",
               request.url?.path.contains(bookingID.uuidString.lowercased()) == true {
                return (response, remoteData)
            }
            return (response, Data())
        }

        let pending = BuddyBookingRecord(
            id: bookingID,
            companionNickname: "阿川",
            hours: 2,
            scheduledAt: acceptedAt.addingTimeInterval(7200),
            bookedAt: acceptedAt,
            priceText: "¥100",
            status: .pendingConfirm
        )
        let submitted = try await service.submit(pending)
        XCTAssertEqual(submitted.status, .awaitingPayment)
        let fetched = try await service.fetchStatus(for: bookingID)
        XCTAssertEqual(fetched.paymentDueAt, dueAt)

        MockURLProtocol.requestHandler = nil
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: APIError.invalidResponse)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
