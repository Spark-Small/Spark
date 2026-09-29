//
//  PersistenceMigration.swift
//  坐标系
//
//  旧 JSON 快照迁移与清理；SwiftData 迁入完成后删除遗留文件。
//

import CoordinateData
import Foundation

enum PersistenceMigration {
    static func legacyFileURL(_ fileName: String) -> URL {
        LocalSnapshotFileStore.fileURL(fileName)
    }

    static func legacyFileExists(_ fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: legacyFileURL(fileName).path)
    }

    static func loadLegacyJSON<T: Codable>(_ fileName: String, fallback: T) -> T {
        LocalSnapshotFileStore.load(fileName, fallback: fallback)
    }

    static func removeLegacyFile(_ fileName: String) {
        let url = legacyFileURL(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
