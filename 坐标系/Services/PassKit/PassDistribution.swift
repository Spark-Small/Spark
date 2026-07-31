//
//  PassDistribution.swift
//  坐标系
//
//  分发通道：App 加入 Wallet、导出未签名包、落盘、.pkpasses 包。
//

import Foundation

enum PassDistributionError: LocalizedError {
    case passNotFound
    case unauthorized
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .passNotFound: "通行证不存在"
        case .unauthorized: "authenticationToken 无效"
        case .exportFailed(let message): message
        }
    }
}

enum PassDistribution {
    /// 通道：读取已签名落盘（供 AddPassToWalletButton）。
    static func signedPassURL(for pass: PassRecord) -> URL {
        PassConfiguration.signedPassesDirectory
            .appendingPathComponent("\(pass.serialNumber).pkpass")
    }

    static func hasSignedPackage(for pass: PassRecord) -> Bool {
        FileManager.default.fileExists(atPath: signedPassURL(for: pass).path)
    }

    /// 通道：导出未签名包到临时文件（ShareLink）。
    static func exportUnsignedTemporary(for pass: PassRecord) throws -> URL {
        let data = try PassPackageBuilder.makeUnsignedPackageData(for: pass)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(pass.serialNumber)-unsigned.pkpass")
        try data.write(to: url, options: [.atomic])
        return url
    }

    /// 通道：写入 Documents/UnsignedWalletPasses 供 Pass Builder。
    @discardableResult
    static func writeUnsignedToDocuments(for pass: PassRecord) throws -> URL {
        PassConfiguration.ensureDirectories()
        let data = try PassPackageBuilder.makeUnsignedPackageData(for: pass)
        let url = PassConfiguration.unsignedPassesDirectory
            .appendingPathComponent("\(pass.serialNumber).pkpass")
        try data.write(to: url, options: [.atomic])
        return url
    }

    /// 通道：多张通行证 → `.pkpasses`（官方 MIME application/vnd.apple.pkpasses）。
    static func makePassBundle(passes: [PassRecord], preferSigned: Bool = true) throws -> URL {
        var files: [(name: String, data: Data)] = []
        for pass in passes {
            let name = "\(pass.serialNumber).pkpass"
            if preferSigned, hasSignedPackage(for: pass),
               let data = try? Data(contentsOf: signedPassURL(for: pass)) {
                files.append((name, data))
            } else {
                files.append((name, try PassPackageBuilder.makeUnsignedPackageData(for: pass)))
            }
        }
        guard !files.isEmpty else {
            throw PassDistributionError.exportFailed("没有可打包的通行证")
        }
        let data = try PassZip.passBundle(files: files)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("coordinate-passes.pkpasses")
        try data.write(to: url, options: [.atomic])
        return url
    }
}
