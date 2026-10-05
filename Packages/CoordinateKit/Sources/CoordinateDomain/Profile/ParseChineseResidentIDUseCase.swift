//
//  ParseChineseResidentIDUseCase.swift
//  CoordinateDomain
//
//  中国居民身份证号（18 位）→ 性别 / 出生日期 / 年龄；校验码按国标。
//

import CryptoKit
import Foundation
import CoordinateModels

public enum ParseChineseResidentIDError: Error, Equatable, Sendable {
    case invalidFormat
    case checksumFailed
    case underage
    case invalidBirthDate
}

public struct ParseChineseResidentIDUseCase: Sendable {
    public init() {}

    /// 从任意 OCR 文本中提取首个合法 18 位身份证号并解析。
    public func parse(fromOCRText text: String, now: Date = .now) throws -> RealNameDemographicsResult {
        let candidates = Self.extractCandidates(from: text)
        for candidate in candidates {
            if let result = try? parse(idNumber: candidate, now: now) {
                return result
            }
        }
        throw ParseChineseResidentIDError.invalidFormat
    }

    public func parse(idNumber raw: String, now: Date = .now) throws -> RealNameDemographicsResult {
        let id = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard id.count == 18, id.dropLast().allSatisfy(\.isNumber) else {
            throw ParseChineseResidentIDError.invalidFormat
        }
        let checkChar = id.last!
        guard checkChar.isNumber || checkChar == "X" else {
            throw ParseChineseResidentIDError.invalidFormat
        }
        guard Self.checksum(for: id) == checkChar else {
            throw ParseChineseResidentIDError.checksumFailed
        }

        let birthDigits = String(id.dropFirst(6).prefix(8))
        guard let birthDate = Self.birthDate(from: birthDigits) else {
            throw ParseChineseResidentIDError.invalidBirthDate
        }
        let age = Self.age(birthDate: birthDate, now: now)
        guard age >= ProfileDemographicsLimits.ageMin else {
            throw ParseChineseResidentIDError.underage
        }
        guard age <= ProfileDemographicsLimits.ageMax else {
            throw ParseChineseResidentIDError.invalidBirthDate
        }

        // 倒数第二位：奇男偶女
        let genderDigit = id[id.index(id.startIndex, offsetBy: 16)]
        let gender: ProfileGender = (Int(String(genderDigit)) ?? 0) % 2 == 1 ? .male : .female

        return RealNameDemographicsResult(
            documentKind: .chineseResidentID,
            gender: gender,
            birthDate: birthDate,
            age: age,
            idNumberFingerprint: Self.fingerprint(id),
            idNumberMasked: Self.masked(id)
        )
    }

    /// 国标校验码。
    public static func checksum(for id18: String) -> Character? {
        guard id18.count == 18 else { return nil }
        let weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
        let map = Array("10X98765432")
        var sum = 0
        for (index, weight) in weights.enumerated() {
            let ch = id18[id18.index(id18.startIndex, offsetBy: index)]
            guard let digit = Int(String(ch)) else { return nil }
            sum += digit * weight
        }
        return map[sum % 11]
    }

    public static func extractCandidates(from text: String) -> [String] {
        let compact = text.uppercased().filter { $0.isNumber || $0 == "X" }
        var results: [String] = []
        guard compact.count >= 18 else { return results }
        let chars = Array(compact)
        for start in 0...(chars.count - 18) {
            let slice = String(chars[start..<(start + 18)])
            if slice.dropLast().allSatisfy(\.isNumber),
               slice.last!.isNumber || slice.last == "X" {
                results.append(slice)
            }
        }
        return results
    }

    public static func birthDate(from yyyymmdd: String) -> Date? {
        guard yyyymmdd.count == 8 else { return nil }
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Asia/Shanghai")
        components.year = Int(yyyymmdd.prefix(4))
        components.month = Int(yyyymmdd.dropFirst(4).prefix(2))
        components.day = Int(yyyymmdd.suffix(2))
        return components.date
    }

    public static func age(birthDate: Date, now: Date) -> Int {
        Calendar(identifier: .gregorian).dateComponents([.year], from: birthDate, to: now).year ?? 0
    }

    public static func fingerprint(_ id: String) -> String {
        let digest = SHA256.hash(data: Data(id.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func masked(_ id: String) -> String {
        guard id.count >= 4 else { return "****" }
        return String(repeating: "*", count: max(0, id.count - 4)) + id.suffix(4)
    }
}
