//
//  ProfileZodiacTests.swift
//

import CoordinateModels
import XCTest

final class ProfileZodiacTests: XCTestCase {
    func testLibraBoundary() {
        XCTAssertEqual(zodiac(month: 9, day: 23), .libra)
        XCTAssertEqual(zodiac(month: 10, day: 23), .libra)
        XCTAssertEqual(zodiac(month: 10, day: 24), .scorpio)
    }

    func testCapricornYearWrap() {
        XCTAssertEqual(zodiac(month: 12, day: 22), .capricorn)
        XCTAssertEqual(zodiac(month: 1, day: 19), .capricorn)
        XCTAssertEqual(zodiac(month: 1, day: 20), .aquarius)
    }

    private func zodiac(month: Int, day: Int) -> ProfileZodiac {
        var components = DateComponents()
        components.year = 2000
        components.month = month
        components.day = day
        let date = Calendar(identifier: .gregorian).date(from: components)!
        return ProfileZodiac.from(birthDate: date)
    }
}
