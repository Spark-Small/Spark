//
//  PassPackageBuilder.swift
//  坐标系
//
//  Build：pass.json + 资源 + manifest → 未签名包（Building a Pass）。
//  签名须在 Pass Builder / 服务端完成，勿把证书打进 App。
//

import CryptoKit
import Foundation
import UIKit

enum PassPackageBuilder {
    static func makePassJSON(for pass: PassRecord) -> [String: Any] {
        var root: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": PassConfiguration.passTypeIdentifier,
            "serialNumber": pass.serialNumber,
            "teamIdentifier": PassConfiguration.teamIdentifier,
            "organizationName": PassConfiguration.organizationName,
            "description": pass.description,
            "logoText": PassConfiguration.logoText,
            "foregroundColor": "rgb(255, 255, 255)",
            "backgroundColor": "rgb(28, 28, 30)",
            "labelColor": "rgb(174, 174, 178)",
            "webServiceURL": pass.webServiceURL,
            "authenticationToken": pass.authenticationToken,
            "barcode": [
                "format": "PKBarcodeFormatQR",
                "message": pass.barcodeMessage,
                "messageEncoding": "iso-8859-1"
            ] as [String: String]
        ]

        root[pass.style.passJSONKey] = [
            "primaryFields": pass.primaryFields.map(fieldDict),
            "secondaryFields": pass.secondaryFields.map(fieldDict),
            "auxiliaryFields": pass.auxiliaryFields.map(fieldDict),
            "backFields": pass.backFields.map(fieldDict)
        ] as [String: Any]

        if let relevantDate = pass.relevantDate {
            root["relevantDate"] = PassDateFormatting.tag(from: relevantDate)
        }
        if let expirationDate = pass.expirationDate {
            root["expirationDate"] = PassDateFormatting.tag(from: expirationDate)
        }
        if pass.voided {
            root["voided"] = true
        }

        return root
    }

    private static func fieldDict(_ field: PassField) -> [String: String] {
        ["key": field.key, "label": field.label, "value": field.value]
    }

    /// 写出未签名 pass 包（zip），供 Pass Builder / 证书流程签名。
    static func makeUnsignedPackageData(for pass: PassRecord) throws -> Data {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("pass-\(pass.serialNumber)", isDirectory: true)
        try? FileManager.default.removeItem(at: temp)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)

        let json = makePassJSON(for: pass)
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: temp.appendingPathComponent("pass.json"), options: [.atomic])

        if let icon = symbolPNG(named: pass.style.systemImage, side: 58) {
            try icon.write(to: temp.appendingPathComponent("icon.png"), options: [.atomic])
            try icon.write(to: temp.appendingPathComponent("paula.r@example.org"), options: [.atomic])
        }
        if let logo = symbolPNG(named: "wallet.bifold.fill", side: 50) {
            try logo.write(to: temp.appendingPathComponent("logo.png"), options: [.atomic])
            try logo.write(to: temp.appendingPathComponent("paula.r@example.org"), options: [.atomic])
        }

        var manifest: [String: String] = [:]
        let contents = try FileManager.default.contentsOfDirectory(at: temp, includingPropertiesForKeys: nil)
        for fileURL in contents where fileURL.lastPathComponent != "manifest.json" {
            let data = try Data(contentsOf: fileURL)
            let digest = Insecure.SHA1.hash(data: data)
            manifest[fileURL.lastPathComponent] = digest.map { String(format: "%02x", $0) }.joined()
        }
        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: [.sortedKeys])
        try manifestData.write(to: temp.appendingPathComponent("manifest.json"), options: [.atomic])

        return try PassZip.directory(temp)
    }

    private static func symbolPNG(named name: String, side: CGFloat) -> Data? {
        let config = UIImage.SymbolConfiguration(pointSize: side * 0.55, weight: .medium)
        guard let image = UIImage(systemName: name, withConfiguration: config) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let rendered = renderer.image { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: side, height: side))
            let size = image.size
            let origin = CGPoint(x: (side - size.width) / 2, y: (side - size.height) / 2)
            image.withTintColor(.white, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(origin: origin, size: size))
        }
        return rendered.pngData()
    }
}

// MARK: - Minimal stored ZIP

enum PassZip {
    static func directory(_ directory: URL) throws -> Data {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
        var output = Data()
        var central = Data()
        var offset: UInt32 = 0
        var count: UInt16 = 0

        for file in files {
            let name = file.lastPathComponent
            let data = try Data(contentsOf: file)
            let nameData = Data(name.utf8)
            let localHeader = zipLocalHeader(nameData: nameData, data: data)
            output.append(localHeader)
            output.append(data)
            let centralHeader = zipCentralHeader(nameData: nameData, data: data, localOffset: offset)
            central.append(centralHeader)
            offset += UInt32(localHeader.count + data.count)
            count += 1
        }

        let centralOffset = offset
        output.append(central)
        output.append(zipEndRecord(entries: count, centralSize: UInt32(central.count), centralOffset: centralOffset))
        return output
    }

    /// 多个已签名/未签名 `.pkpass` → `.pkpasses` 包（官方分发多票）。
    static func passBundle(files: [(name: String, data: Data)]) throws -> Data {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("pkpasses-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.removeItem(at: temp)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        for file in files {
            try file.data.write(
                to: temp.appendingPathComponent(file.name),
                options: [.atomic]
            )
        }
        return try directory(temp)
    }

    private static func zipLocalHeader(nameData: Data, data: Data) -> Data {
        var h = Data()
        h.append(contentsOf: [0x50, 0x4b, 0x03, 0x04])
        h.append(u16: 20)
        h.append(u16: 0)
        h.append(u16: 0)
        h.append(u16: 0); h.append(u16: 0)
        h.append(u32: crc32(data))
        h.append(u32: UInt32(data.count))
        h.append(u32: UInt32(data.count))
        h.append(u16: UInt16(nameData.count))
        h.append(u16: 0)
        h.append(nameData)
        return h
    }

    private static func zipCentralHeader(nameData: Data, data: Data, localOffset: UInt32) -> Data {
        var h = Data()
        h.append(contentsOf: [0x50, 0x4b, 0x01, 0x02])
        h.append(u16: 20); h.append(u16: 20)
        h.append(u16: 0); h.append(u16: 0)
        h.append(u16: 0); h.append(u16: 0)
        h.append(u32: crc32(data))
        h.append(u32: UInt32(data.count))
        h.append(u32: UInt32(data.count))
        h.append(u16: UInt16(nameData.count))
        h.append(u16: 0); h.append(u16: 0)
        h.append(u16: 0); h.append(u16: 0)
        h.append(u32: 0)
        h.append(u32: localOffset)
        h.append(nameData)
        return h
    }

    private static func zipEndRecord(entries: UInt16, centralSize: UInt32, centralOffset: UInt32) -> Data {
        var h = Data()
        h.append(contentsOf: [0x50, 0x4b, 0x05, 0x06])
        h.append(u16: 0); h.append(u16: 0)
        h.append(u16: entries); h.append(u16: entries)
        h.append(u32: centralSize)
        h.append(u32: centralOffset)
        h.append(u16: 0)
        return h
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffff_ffff
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xff)
            crc = (crc >> 8) ^ crcTable[idx]
        }
        return crc ^ 0xffff_ffff
    }

    private static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (0xedb88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()
}

private extension Data {
    mutating func append(u16 value: UInt16) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }

    mutating func append(u32 value: UInt32) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
