//
//  ParsePassportIdentityUseCase.swift
//  CoordinateDomain
//
//  护照 OCR / MRZ → 性别 / 出生日期 / 年龄；不存护照号明文。
//

import Foundation
import CoordinateModels

public enum ParsePassportIdentityError: Error, Equatable, Sendable {
    case unrecognized
    case underage
    case invalidBirthDate
    case missingSex
    case missingDocumentNumber
}

public struct ParsePassportIdentityUseCase: Sendable {
    public init() {}

    public func parse(fromOCRText text: String, now: Date = .now) throws -> RealNameDemographicsResult {
        do {
            return try parseMRZ(from: text, now: now)
        } catch ParsePassportIdentityError.underage {
            throw ParsePassportIdentityError.underage
        } catch ParsePassportIdentityError.invalidBirthDate {
            throw ParsePassportIdentityError.invalidBirthDate
        } catch {
            return try parseVisualZone(from: text, now: now)
        }
    }

    // MARK: - MRZ (TD3 line 2)

    private func parseMRZ(from text: String, now: Date) throws -> RealNameDemographicsResult {
        let lines = Self.mrzCandidateLines(from: text)
        for line in lines {
            guard line.count >= 28 else { continue }
            let padded = line.count >= 44
                ? String(line.prefix(44))
                : line.padding(toLength: 44, withPad: "<", startingAt: 0)
            let chars = Array(padded)
            let docNumber = String(chars[0..<9]).replacingOccurrences(of: "<", with: "")
            guard docNumber.count >= 6 else { continue }

            let birthRaw = String(chars[13..<19])
            guard let birthDate = Self.dateFromYYMMDD(birthRaw, now: now) else { continue }
            guard let gender = Self.gender(fromMRZ: chars[20]) else { continue }

            let age = ParseChineseResidentIDUseCase.age(birthDate: birthDate, now: now)
            guard age >= ProfileDemographicsLimits.ageMin else {
                throw ParsePassportIdentityError.underage
            }
            guard age <= ProfileDemographicsLimits.ageMax else {
                throw ParsePassportIdentityError.invalidBirthDate
            }

            let normalized = docNumber.uppercased()
            return RealNameDemographicsResult(
                documentKind: .passport,
                gender: gender,
                birthDate: birthDate,
                age: age,
                idNumberFingerprint: ParseChineseResidentIDUseCase.fingerprint(normalized),
                idNumberMasked: ParseChineseResidentIDUseCase.masked(normalized)
            )
        }
        throw ParsePassportIdentityError.unrecognized
    }

    // MARK: - Visual zone

    private func parseVisualZone(from text: String, now: Date) throws -> RealNameDemographicsResult {
        guard Self.looksLikePassport(text) else {
            throw ParsePassportIdentityError.unrecognized
        }
        guard let gender = Self.extractGender(from: text) else {
            throw ParsePassportIdentityError.missingSex
        }
        guard let birthDate = Self.extractBirthDate(from: text, now: now) else {
            throw ParsePassportIdentityError.invalidBirthDate
        }
        guard let docNumber = Self.extractPassportNumber(from: text) else {
            throw ParsePassportIdentityError.missingDocumentNumber
        }

        let age = ParseChineseResidentIDUseCase.age(birthDate: birthDate, now: now)
        guard age >= ProfileDemographicsLimits.ageMin else {
            throw ParsePassportIdentityError.underage
        }
        guard age <= ProfileDemographicsLimits.ageMax else {
            throw ParsePassportIdentityError.invalidBirthDate
        }

        let normalized = docNumber.uppercased()
        return RealNameDemographicsResult(
            documentKind: .passport,
            gender: gender,
            birthDate: birthDate,
            age: age,
            idNumberFingerprint: ParseChineseResidentIDUseCase.fingerprint(normalized),
            idNumberMasked: ParseChineseResidentIDUseCase.masked(normalized)
        )
    }

    // MARK: - Helpers

    public static func mrzCandidateLines(from text: String) -> [String] {
        text
            .uppercased()
            .components(separatedBy: .newlines)
            .map { $0.filter { $0.isLetter || $0.isNumber || $0 == "<" } }
            .filter { line in
                line.count >= 28
                    && line.contains(where: \.isNumber)
                    && line.filter(\.isLetter).count >= 3
            }
    }

    public static func looksLikePassport(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "").uppercased()
        let needles = ["护照", "PASSPORT", "护照号码", "PASSPORTNO", "中华人民共和国", "P<", "CHN"]
        return needles.contains(where: { compact.contains($0.uppercased()) })
            || !mrzCandidateLines(from: text).isEmpty
    }

    public static func gender(fromMRZ char: Character) -> ProfileGender? {
        switch char {
        case "M": .male
        case "F": .female
        default: nil
        }
    }

    public static func extractGender(from text: String) -> ProfileGender? {
        let upper = text.uppercased()
        let patterns = [
            #"性别\s*[/／]?\s*SEX\s*[:：]?\s*([男女MF])"#,
            #"SEX\s*[:：]?\s*([MF男女])"#,
            #"性别\s*[:：]?\s*([男女MF])"#,
        ]
        let ns = upper as NSString
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let full = NSRange(location: 0, length: ns.length)
            if let match = regex.firstMatch(in: upper, range: full), match.numberOfRanges >= 2 {
                let token = ns.substring(with: match.range(at: 1))
                if token.contains("男") || token == "M" { return .male }
                if token.contains("女") || token == "F" { return .female }
            }
        }
        if upper.contains("男") && !upper.contains("女") { return .male }
        if upper.contains("女") && !upper.contains("男") { return .female }
        return nil
    }

    public static func extractBirthDate(from text: String, now: Date) -> Date? {
        let ns = text as NSString
        let ymdPatterns = [
            #"(?:出生日期|出生|DATE OF BIRTH|BIRTH)\s*[:：/\s]*(\d{4})\s*[年\-/\.]\s*(\d{1,2})\s*[月\-/\.]\s*(\d{1,2})"#,
            #"(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日"#,
        ]
        for pattern in ymdPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            else { continue }
            let full = NSRange(location: 0, length: ns.length)
            if let match = regex.firstMatch(in: text, range: full), match.numberOfRanges >= 4 {
                let y = Int(ns.substring(with: match.range(at: 1)))
                let m = Int(ns.substring(with: match.range(at: 2)))
                let d = Int(ns.substring(with: match.range(at: 3)))
                if let date = birthDate(year: y, month: m, day: d) { return date }
            }
        }
        if let regex = try? NSRegularExpression(
            pattern: #"(?:出生|BIRTH)[^\d]{0,12}(\d{6})"#,
            options: [.caseInsensitive]
        ) {
            let full = NSRange(location: 0, length: ns.length)
            if let match = regex.firstMatch(in: text, range: full), match.numberOfRanges >= 2 {
                let yymmdd = ns.substring(with: match.range(at: 1))
                if let date = dateFromYYMMDD(yymmdd, now: now) { return date }
            }
        }
        return nil
    }

    public static func extractPassportNumber(from text: String) -> String? {
        let upper = text.uppercased()
        let patterns = [
            #"(?:护照号码|护照号|PASSPORT\s*NO\.?|PASSPORT\s*NUMBER)\s*[:：]?\s*([A-Z][A-Z0-9]{6,9})"#,
            #"\b([EGDSP]\d{8})\b"#,
            #"\b([A-Z]\d{7,8})\b"#,
        ]
        let ns = upper as NSString
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let full = NSRange(location: 0, length: ns.length)
            if let match = regex.firstMatch(in: upper, range: full), match.numberOfRanges >= 2 {
                return ns.substring(with: match.range(at: 1))
            }
        }
        return nil
    }

    public static func dateFromYYMMDD(_ raw: String, now: Date) -> Date? {
        guard raw.count == 6, raw.allSatisfy(\.isNumber),
              let yy = Int(raw.prefix(2)),
              let mm = Int(raw.dropFirst(2).prefix(2)),
              let dd = Int(raw.suffix(2))
        else { return nil }
        return birthDate(year: centuryYear(yy, now: now), month: mm, day: dd)
    }

    private static func centuryYear(_ yy: Int, now: Date) -> Int {
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: now)
        let y2000 = 2000 + yy
        let age2000 = currentYear - y2000
        if (0...100).contains(age2000) { return y2000 }
        return 1900 + yy
    }

    private static func birthDate(year: Int?, month: Int?, day: Int?) -> Date? {
        guard let year, let month, let day else { return nil }
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Asia/Shanghai")
        components.year = year
        components.month = month
        components.day = day
        return components.date
    }
}
