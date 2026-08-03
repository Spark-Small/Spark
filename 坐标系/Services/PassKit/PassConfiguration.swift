//
//  PassConfiguration.swift
//  坐标系
//
//  PassKit 配置：Pass Type ID、Team、本机更新 Web Service URL、签名落盘目录。
//

import Foundation

enum PassConfiguration {
    /// Developer → Identifiers → Pass Type IDs 中注册后填入
    static let passTypeIdentifier = "pass.coordinate.app"
    /// 与 Xcode DEVELOPMENT_TEAM 一致
    static let teamIdentifier = "A95ZH5QY7B"
    static let organizationName = "坐标系"
    static let logoText = "坐标系"

    /// 官方更新 Web Service 基址（本机演示占位；真机需 HTTPS）。
    /// 设备注册路径：`{webServiceURL}/v1/devices/...`
    static let webServiceURL = "https://pass.coordinate.app/v1"

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 已签名 `.pkpass`：`{serialNumber}.pkpass`
    static var signedPassesDirectory: URL {
        documentsDirectory.appendingPathComponent("SignedWalletPasses", isDirectory: true)
    }

    /// 未签名导出落盘（供 Pass Builder）
    static var unsignedPassesDirectory: URL {
        documentsDirectory.appendingPathComponent("UnsignedWalletPasses", isDirectory: true)
    }

    static var isSigningConfigured: Bool {
        guard FileManager.default.fileExists(atPath: signedPassesDirectory.path),
              let contents = try? FileManager.default.contentsOfDirectory(atPath: signedPassesDirectory.path)
        else { return false }
        return contents.contains { $0.hasSuffix(".pkpass") }
    }

    static func ensureDirectories() {
        try? FileManager.default.createDirectory(
            at: signedPassesDirectory,
            withIntermediateDirectories: true
        )
        try? FileManager.default.createDirectory(
            at: unsignedPassesDirectory,
            withIntermediateDirectories: true
        )
    }
}
