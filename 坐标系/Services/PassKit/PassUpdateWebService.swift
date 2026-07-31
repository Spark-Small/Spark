//
//  PassUpdateWebService.swift
//  坐标系
//
//  本机模拟 Apple Pass 更新 Web Service 契约（非真 HTTPS / APNs）。
//  官方：register → push → list serials → get latest pass → unregister。
//

import Foundation
import Observation

struct PassDeviceRegistration: Identifiable, Codable, Hashable {
    var id: String { deviceLibraryIdentifier }
    let deviceLibraryIdentifier: String
    let pushToken: String
    let passTypeIdentifier: String
    let serialNumber: String
    let registeredAt: Date
}

struct PassUpdateEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let at: Date
    let kind: Kind
    let detail: String
    let serialNumber: String?

    enum Kind: String, Codable, Hashable {
        case register
        case unregister
        case pushSimulated
        case listSerials
        case fetchLatest
        case void
        case update

        var displayName: String {
            switch self {
            case .register: "设备注册"
            case .unregister: "取消注册"
            case .pushSimulated: "模拟推送"
            case .listSerials: "拉取可更新序列号"
            case .fetchLatest: "拉取最新通行证"
            case .void: "作废"
            case .update: "字段更新"
            }
        }
    }
}

struct PassSerialNumbersResponse: Hashable {
    let serialNumbers: [String]
    let lastUpdated: String
}

@MainActor
@Observable
final class PassUpdateWebService {
    static let shared = PassUpdateWebService()

    private(set) var registrations: [PassDeviceRegistration] = []
    private(set) var events: [PassUpdateEvent] = []

    private static let registrationsFile = "pass_device_registrations.json"
    private static let eventsFile = "pass_update_events.json"
    private static let maxEvents = 80

    private init() {
        registrations = Self.load([PassDeviceRegistration].self, file: Self.registrationsFile) ?? []
        events = Self.load([PassUpdateEvent].self, file: Self.eventsFile) ?? []
    }

    /// POST /v1/devices/{deviceLibraryIdentifier}/registrations/{passTypeIdentifier}/{serialNumber}
    @discardableResult
    func registerDevice(
        deviceLibraryIdentifier: String,
        pushToken: String,
        passTypeIdentifier: String = PassConfiguration.passTypeIdentifier,
        serialNumber: String,
        authenticationToken: String,
        expectedToken: String
    ) -> Bool {
        guard authenticationToken == expectedToken else {
            appendEvent(.register, detail: "鉴权失败", serial: serialNumber)
            return false
        }
        registrations.removeAll {
            $0.deviceLibraryIdentifier == deviceLibraryIdentifier
                && $0.serialNumber == serialNumber
                && $0.passTypeIdentifier == passTypeIdentifier
        }
        let row = PassDeviceRegistration(
            deviceLibraryIdentifier: deviceLibraryIdentifier,
            pushToken: pushToken,
            passTypeIdentifier: passTypeIdentifier,
            serialNumber: serialNumber,
            registeredAt: .now
        )
        registrations.append(row)
        persistRegistrations()
        appendEvent(
            .register,
            detail: "device=\(deviceLibraryIdentifier.prefix(8))… token=\(pushToken.prefix(8))…",
            serial: serialNumber
        )
        return true
    }

    /// DELETE …/registrations/{passTypeIdentifier}/{serialNumber}
    func unregisterDevice(
        deviceLibraryIdentifier: String,
        passTypeIdentifier: String = PassConfiguration.passTypeIdentifier,
        serialNumber: String,
        authenticationToken: String,
        expectedToken: String
    ) -> Bool {
        guard authenticationToken == expectedToken else { return false }
        registrations.removeAll {
            $0.deviceLibraryIdentifier == deviceLibraryIdentifier
                && $0.serialNumber == serialNumber
                && $0.passTypeIdentifier == passTypeIdentifier
        }
        persistRegistrations()
        appendEvent(.unregister, detail: "device=\(deviceLibraryIdentifier.prefix(8))…", serial: serialNumber)
        return true
    }

    /// 业务变更后模拟 APNs content-available 推送。
    func notePassUpdated(serialNumber: String, reason: String) {
        let targets = registrations.filter { $0.serialNumber == serialNumber }
        let detail: String
        if targets.isEmpty {
            detail = "\(reason)；无已注册设备（跳过推送）"
        } else {
            detail = "\(reason)；模拟推送 → \(targets.count) 台设备"
        }
        appendEvent(.pushSimulated, detail: detail, serial: serialNumber)
        appendEvent(.update, detail: reason, serial: serialNumber)
    }

    func noteVoid(serialNumber: String) {
        notePassUpdated(serialNumber: serialNumber, reason: "通行证已作废 (voided)")
        appendEvent(.void, detail: "voided=true", serial: serialNumber)
    }

    /// GET /v1/devices/{deviceLibraryIdentifier}/registrations/{passTypeIdentifier}?passesUpdatedSince=
    func serialNumbersUpdatedSince(
        deviceLibraryIdentifier: String,
        passTypeIdentifier: String = PassConfiguration.passTypeIdentifier,
        passesUpdatedSince: String?,
        passes: [PassRecord]
    ) -> PassSerialNumbersResponse {
        let registeredSerials = Set(
            registrations
                .filter {
                    $0.deviceLibraryIdentifier == deviceLibraryIdentifier
                        && $0.passTypeIdentifier == passTypeIdentifier
                }
                .map(\.serialNumber)
        )
        let since = passesUpdatedSince.flatMap(PassDateFormatting.date(from:))
        let updated = passes.filter { pass in
            guard registeredSerials.contains(pass.serialNumber) else { return false }
            guard let since else { return true }
            return pass.lastUpdated > since
        }
        let lastTag = updated.map(\.lastUpdated).max().map(PassDateFormatting.tag(from:))
            ?? PassDateFormatting.tag(from: .now)
        let response = PassSerialNumbersResponse(
            serialNumbers: updated.map(\.serialNumber),
            lastUpdated: lastTag
        )
        appendEvent(
            .listSerials,
            detail: "since=\(passesUpdatedSince ?? "nil") → \(response.serialNumbers.count) 张",
            serial: nil
        )
        return response
    }

    /// GET /v1/passes/{passTypeIdentifier}/{serialNumber}
    func latestPassPackage(
        serialNumber: String,
        authenticationToken: String,
        pass: PassRecord?
    ) throws -> Data {
        guard let pass, pass.serialNumber == serialNumber else {
            throw PassDistributionError.passNotFound
        }
        guard authenticationToken == pass.authenticationToken else {
            throw PassDistributionError.unauthorized
        }
        appendEvent(.fetchLatest, detail: "拉取最新未签名包", serial: serialNumber)
        return try PassPackageBuilder.makeUnsignedPackageData(for: pass)
    }

    /// 演示：为本机生成 deviceLibraryID 并注册当前通行证。
    func simulateDeviceRegister(for pass: PassRecord) {
        let deviceID = LocalUserIdentity.current.uuidString
        let push = "demo-push-\(UUID().uuidString.prefix(8))"
        _ = registerDevice(
            deviceLibraryIdentifier: deviceID,
            pushToken: push,
            serialNumber: pass.serialNumber,
            authenticationToken: pass.authenticationToken,
            expectedToken: pass.authenticationToken
        )
    }

    func resetAll() {
        registrations = []
        events = []
        persistRegistrations()
        persistEvents()
    }

    private func appendEvent(_ kind: PassUpdateEvent.Kind, detail: String, serial: String?) {
        let event = PassUpdateEvent(
            id: UUID(),
            at: .now,
            kind: kind,
            detail: detail,
            serialNumber: serial
        )
        events.insert(event, at: 0)
        if events.count > Self.maxEvents {
            events = Array(events.prefix(Self.maxEvents))
        }
        persistEvents()
    }

    private func persistRegistrations() {
        Self.save(registrations, file: Self.registrationsFile)
    }

    private func persistEvents() {
        Self.save(events, file: Self.eventsFile)
    }

    private static func load<T: Decodable>(_ type: T.Type, file: String) -> T? {
        let url = PassConfiguration.documentsDirectory.appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, file: String) {
        let url = PassConfiguration.documentsDirectory.appendingPathComponent(file)
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
