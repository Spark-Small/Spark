//
//  ProfileSnapshotCatalog.swift
//  坐标系
//

import CoordinateData
import CoordinateModels

struct AppProfileSnapshotPolicy: ProfileSnapshotPersistencePolicy {
    func fallbackSnapshot() -> ProfileSnapshot { .seed }
}
