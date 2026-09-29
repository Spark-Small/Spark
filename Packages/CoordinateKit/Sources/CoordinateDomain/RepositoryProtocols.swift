//
//  RepositoryProtocols.swift
//  CoordinateDomain
//

import Foundation

public protocol ActivitiesRepository: SnapshotRepository where Snapshot == ActivitiesSnapshot {}
public protocol MessagesRepository: SnapshotRepository where Snapshot == MessagesSnapshot {}
public protocol BuddiesRepository: SnapshotRepository where Snapshot == BuddiesSnapshot {}
public protocol CommunityRepository: SnapshotRepository where Snapshot == CommunitySnapshot {}
public protocol ProfileRepository: SnapshotRepository where Snapshot == ProfileSnapshot {}
public protocol EngagementRepository: SnapshotRepository where Snapshot == ActivityEngagementSnapshot {}
