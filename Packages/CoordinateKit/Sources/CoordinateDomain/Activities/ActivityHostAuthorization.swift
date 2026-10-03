//
//  ActivityHostAuthorization.swift
//  CoordinateDomain
//
//  发起人校验：优先 user id，兼容仅有昵称的旧快照。
//

import Foundation
import CoordinateModels

public enum ActivityHostAuthorization {
    public static func isHost(
        _ activity: Activity,
        hostName: String,
        hostUserID: UUID?
    ) -> Bool {
        if let hostUserID, let activityHostID = activity.hostUserID {
            return activityHostID == hostUserID
        }
        return activity.hostName == hostName
    }
}
