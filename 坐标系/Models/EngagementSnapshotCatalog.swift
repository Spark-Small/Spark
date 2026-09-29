//
//  EngagementSnapshotCatalog.swift
//  坐标系
//

import CoordinateData
import CoordinateModels

struct AppEngagementSnapshotPolicy: EngagementSnapshotPersistencePolicy {
    func fallbackSnapshot() -> ActivityEngagementSnapshot { .seed }
}
