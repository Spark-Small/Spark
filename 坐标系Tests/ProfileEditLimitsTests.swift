//
//  ProfileEditLimitsTests.swift
//  坐标系Tests
//

import XCTest
@testable import 坐标系

final class ProfileEditLimitsTests: XCTestCase {
    func testNormalizeHandleStripsAtAndIllegalCharacters() {
        XCTAssertEqual(ProfileEditLimits.normalizeHandle("@Lin_Yu!"), "Lin_Yu")
        XCTAssertEqual(ProfileEditLimits.normalizeHandle("  abc  "), "abc")
    }

    func testNormalizeHandleRespectsMaxLength() {
        let raw = String(repeating: "a", count: ProfileEditLimits.handleMax + 8)
        XCTAssertEqual(
            ProfileEditLimits.normalizeHandle(raw).count,
            ProfileEditLimits.handleMax
        )
    }

    func testClampedBio() {
        let raw = String(repeating: "简", count: ProfileEditLimits.bioMax + 3)
        XCTAssertEqual(
            ProfileEditLimits.clamped(raw, max: ProfileEditLimits.bioMax).count,
            ProfileEditLimits.bioMax
        )
    }
}
