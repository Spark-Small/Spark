//
//  AppDomainEvents.swift
//  坐标系
//

import Foundation

enum AppDomainEvent {
    case activityJoined(Activity.ID)
    case activityLeft(Activity.ID, wasHost: Bool)
    case activityPublished(Activity.ID)
    case activityCancelled(Activity.ID)
    case activityUpdated(Activity.ID)
    case activityEdited(Activity.ID)
    case profileUpdated(previousName: String, user: AppUser)
    case onboardingCompleted(interests: [String])
    case userBlocked(String)
    case userUnblocked(String)
    case moderationTicketAdded(ModerationTicket)
    case localDataReloaded(ProfileSnapshot)
    case conversationsChanged
    case buddyRecordsChanged
    case statsRefreshRequested
    case recommendationRefreshRequested
}

@MainActor
struct AppSyncOrchestrator {
    unowned let app: AppModel
    private let activityConversation = ActivityConversationSyncService()
    private let profileSync = AppProfileSyncService()
    private let derivedState = AppDerivedStateService()
    private let safetySync = AppSafetySyncService()
    private let trustSync = TrustBehaviorSyncService()

    func handle(_ event: AppDomainEvent) {
        trustSync.handle(event, app: app)
        switch event {
        case .activityJoined(let activityID):
            activityConversation.handleJoin(activityID: activityID, app: app)
            derivedState.refreshAll(app: app)

        case .activityLeft(let activityID, let wasHost):
            activityConversation.handleLeave(activityID: activityID, wasHost: wasHost, app: app)
            derivedState.refreshAll(app: app)

        case .activityPublished(let activityID):
            activityConversation.handlePublish(activityID: activityID, app: app)
            derivedState.refreshAll(app: app)

        case .activityCancelled(let activityID):
            activityConversation.handleCancel(activityID: activityID, app: app)
            derivedState.refreshAll(app: app)

        case .activityUpdated(let activityID):
            activityConversation.syncMetadata(activityID: activityID, app: app)

        case .activityEdited(let activityID):
            activityConversation.syncMetadata(activityID: activityID, app: app)
            derivedState.refreshAll(app: app)

        case .profileUpdated(let previousName, let user):
            profileSync.apply(user: user, previousName: previousName, app: app)
            derivedState.refreshAll(app: app)

        case .onboardingCompleted(let interests):
            profileSync.applyOnboarding(interests: interests, app: app)
            derivedState.refreshAll(app: app)
            app.persistProfile()

        case .userBlocked(let name):
            safetySync.blockUser(name, app: app)
            app.persistProfile()
            derivedState.refreshProfileStats(app: app)

        case .userUnblocked(let name):
            safetySync.unblockUser(name, app: app)
            app.persistProfile()

        case .moderationTicketAdded(let ticket):
            safetySync.addModerationTicket(ticket, app: app)
            app.persistProfile()

        case .localDataReloaded(let profileSnapshot):
            profileSync.apply(snapshot: profileSnapshot, app: app)
            derivedState.refreshAll(app: app)

        case .conversationsChanged:
            derivedState.refreshAll(app: app)

        case .buddyRecordsChanged:
            derivedState.refreshAll(app: app)

        case .statsRefreshRequested:
            derivedState.refreshProfileStats(app: app)

        case .recommendationRefreshRequested:
            derivedState.refreshRecommendations(app: app)
        }
    }
}
