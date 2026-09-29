//
//  SnapshotCodableCompare.swift
//  CoordinateData
//

import Foundation

public enum SnapshotCodableCompare {
    public static func equal<T: Codable>(_ lhs: T, _ rhs: T) -> Bool {
        guard let lhsData = try? JSONEncoder().encode(lhs),
              let rhsData = try? JSONEncoder().encode(rhs)
        else { return false }
        return lhsData == rhsData
    }
}
