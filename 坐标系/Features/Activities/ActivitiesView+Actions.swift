//
//  ActivitiesView+Actions.swift
//  坐标系
//
//  活动 Tab：报名 / 深链 / 欢迎引导 / 发布回调。
//

import SwiftUI
import CoordinateModels

extension ActivitiesView {
    var joinSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.presentation.joinSuccessActivityID != nil && navigation.isEmpty },
            set: { if !$0 { model.dismissJoinSuccess() } }
        )
    }

    var publishSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.presentation.publishSuccessActivityID != nil && navigation.isEmpty },
            set: { if !$0 { model.dismissPublishSuccess() } }
        )
    }

    func beginCompose() {
        model.presentation.beginCompose()
    }

    func presentWelcomeGuideIfNeeded() {
        guard !app.welcomeGuide.hasSeenGuide, !showWelcomeGuide else { return }
        showWelcomeGuide = true
    }

    func finishWelcomeGuideIfNeeded() {
        guard !app.welcomeGuide.hasSeenGuide else { return }
        app.welcomeGuide.finish(app: app)
    }

    func finishWelcomeGuide(with intent: AppWelcomeIntent) {
        app.welcomeGuide.finish(app: app, intent: intent)
    }

    func openJourney(_ activity: Activity) {
        navigation.path.append(
            ActivityZoomSource(
                activityID: activity.id,
                slot: "journey-todo",
                intent: .participantPass
            )
        )
    }

    func open(_ activity: Activity) {
        navigation.path.append(ActivityZoomSource(activityID: activity.id, slot: "programmatic"))
    }

    /// 发现根落地：退出「最近看过」、清成功 Sheet、重置栈（对齐搭子 `landOnDiscover`）。
    func landOnActivitiesDiscoverRoot() {
        model.exitBrowseRecents()
        model.dismissJoinSuccess()
        model.dismissPublishSuccess()
        navigation.reset()
        discoverBrowseScrollRequest += 1
    }

    func consumeDiscoverFocusLandIfNeeded() {
        let token = app.activitiesDiscoverBrowseFocusToken
        guard token > 0, token != consumedDiscoverFocusToken else { return }
        consumedDiscoverFocusToken = token
        landOnActivitiesDiscoverRoot()
    }

    func landOnEmbeddedCommunityFeed() {
        landOnActivitiesDiscoverRoot()
        navigation.path.append(ActivitiesBrowseRoute.communityFeed)
    }

    func consumePendingActivityOpen() {
        guard let id = app.pendingActivityID else { return }
        let followUp = app.pendingActivityFollowUp
        app.pendingActivityID = nil
        app.pendingActivityFollowUp = .none
        landOnActivitiesDiscoverRoot()

        switch followUp {
        case .none:
            navigation.path.append(ActivityZoomSource(activityID: id, slot: "notification"))
        case .openJourney:
            navigation.path.append(
                ActivityZoomSource(
                    activityID: id,
                    slot: "notification-journey",
                    intent: .participantPass
                )
            )
        case .journeyFeedback, .journeyRecap:
            app.pendingActivityJourneyFollowUp = followUp
            navigation.path.append(
                ActivityZoomSource(
                    activityID: id,
                    slot: "notification-journey",
                    intent: .participantPass
                )
            )
        }
    }

    func join(_ activity: Activity) {
        PlatformMotion.withAnimation(.snappy) {
            _ = app.quickJoinActivity(activity) { open(activity) }
        }
    }

    func openGroup(for activity: Activity) {
        app.activities.markActivityGroupOpened(activity.id)
        guard let route = app.prepareActivityGroupChatRoute(for: activity) else { return }
        navigation.openActivityGroupChat(for: activity, route: route)
    }

    func openClubConversation(_ conversationID: UUID) {
        guard let conversation = messages.conversations.first(where: { $0.id == conversationID }),
              conversation.kind == .circle,
              let circleID = conversation.relatedCircleID,
              let circle = buddies.circle(id: circleID)
        else {
            app.openMessages(conversationID: conversationID)
            return
        }
        guard let route = app.prepareClubGroupChatRoute(for: circle) else { return }
        navigation.openClubGroupChat(for: circle, route: route)
    }

    func handlePublish(_ payload: ActivityComposePayload) -> Activity.ID? {
        guard let id = model.publish(
            title: payload.title,
            category: payload.category,
            location: payload.location,
            date: payload.date,
            capacity: payload.capacity,
            fee: payload.fee,
            summary: payload.summary,
            tags: payload.tags,
            localCoverName: payload.localCoverName,
            latitude: payload.latitude,
            longitude: payload.longitude
        ) else { return nil }

        app.handle(.activityPublished(id))
        if let activity = model.activity(id: id) {
            open(activity)
        }
        return id
    }

    func handleUpdate(_ id: Activity.ID, _ payload: ActivityComposePayload) {
        app.applyActivityUpdate(
            id: id,
            title: payload.title,
            category: payload.category,
            location: payload.location,
            date: payload.date,
            capacity: payload.capacity,
            fee: payload.fee,
            summary: payload.summary,
            tags: payload.tags,
            localCoverName: payload.localCoverName,
            latitude: payload.latitude,
            longitude: payload.longitude
        )
    }

    func bootstrapLocationIfNeeded() async {
        guard model.quickFilters.contains(.nearby) else { return }
        location.promptWhenInUseIfNeeded()
        for _ in 0..<12 {
            if location.coordinate != nil { break }
            if !location.canPromptWhenInUse,
               !location.isAuthorized {
                break
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
        model.refreshDistancesFromLocation()
    }
}
