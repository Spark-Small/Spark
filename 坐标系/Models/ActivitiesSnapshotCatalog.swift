//
//  ActivitiesSnapshotCatalog.swift
//  坐标系
//
//  活动目录种子合并与修复策略（App 层种子依赖 SampleData / .seed）。
//

import CoordinateData
import CoordinateDomain
import CoordinateModels

enum ActivitiesSnapshotCatalog {
    static func repair(from previous: ActivitiesSnapshot) -> ActivitiesSnapshot {
        AppComposition.activitiesParticipation.repairSnapshot.execute(
            seed: .seed,
            previous: previous
        )
    }
}

struct AppActivitiesSnapshotPolicy: ActivitiesSnapshotPersistencePolicy {
    func fallbackSnapshot() -> ActivitiesSnapshot { .seed }

    func needsRepairOnLoad(_ snapshot: ActivitiesSnapshot) -> Bool {
        !snapshot.activities.contains(where: { !$0.isPast })
    }

    func repairSnapshot(from previous: ActivitiesSnapshot) -> ActivitiesSnapshot {
        ActivitiesSnapshotCatalog.repair(from: previous)
    }
}
