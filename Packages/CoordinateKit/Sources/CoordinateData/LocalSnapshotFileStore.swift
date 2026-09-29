//
//  LocalSnapshotFileStore.swift
//  CoordinateData
//

import Foundation

public enum LocalSnapshotFileStore {
    public static func fileURL(_ name: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent(name)
    }

    public static func load<T: Codable>(_ fileName: String, fallback: T) -> T {
        let url = fileURL(fileName)
        let fm = FileManager.default

        guard fm.fileExists(atPath: url.path) else {
            // 首次安装：写入种子合法。
            save(fallback, to: fileName)
            return fallback
        }

        guard let data = try? Data(contentsOf: url) else {
            // 读失败：保留原文件，不覆盖。
            return fallback
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // 解码失败：备份坏文件，禁止用种子覆盖用户数据。
            backupCorruptFile(at: url)
            return fallback
        }
    }

    public static func save<T: Encodable>(_ value: T, to fileName: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: fileURL(fileName), options: .atomic)
    }

    /// 将无法解码的快照挪到旁路文件，便于日后迁移 / 支持排查。
    private static func backupCorruptFile(at url: URL) {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = url.appendingPathExtension("corrupt.\(stamp)")
        let fm = FileManager.default
        if fm.fileExists(atPath: backup.path) {
            try? fm.removeItem(at: backup)
        }
        try? fm.moveItem(at: url, to: backup)
    }
}
