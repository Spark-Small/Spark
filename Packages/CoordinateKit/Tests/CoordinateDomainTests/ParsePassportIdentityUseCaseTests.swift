import CoordinateDomain
import CoordinateModels
import XCTest

final class ParsePassportIdentityUseCaseTests: XCTestCase {
    private let parse = ParsePassportIdentityUseCase()

    func testParsesMRZLine2() throws {
        // PassportNo E12345678 / birth 1990-01-15 / sex F
        let mrz2 = "E123456787CHN9001152F3012315<<<<<<<<<<<<<<06"
        let ocr = """
        P<CHNZHANG<<SAN<<<<<<<<<<<<<<<<<<<<<<<<<<
        \(mrz2)
        """
        let result = try parse.parse(fromOCRText: ocr, now: date(2026, 6, 1))
        XCTAssertEqual(result.documentKind, .passport)
        XCTAssertEqual(result.gender, .female)
        XCTAssertEqual(result.age, 36)
        XCTAssertTrue(result.idNumberMasked.hasSuffix("5678"))
        XCTAssertEqual(result.idNumberFingerprint.count, 64)
    }

    func testParsesVisualZoneChinese() throws {
        let ocr = """
        中华人民共和国
        护照 PASSPORT
        护照号码/Passport No. E87654321
        性别/Sex 男/M
        出生日期/Date of birth 1992年03月08日
        """
        let result = try parse.parse(fromOCRText: ocr, now: date(2026, 6, 1))
        XCTAssertEqual(result.documentKind, .passport)
        XCTAssertEqual(result.gender, .male)
        XCTAssertEqual(result.age, 34)
        XCTAssertTrue(result.idNumberMasked.hasSuffix("4321"))
    }

    func testRejectsUnderage() {
        let mrz2 = "E123456787CHN1501012M3012315<<<<<<<<<<<<<<06"
        XCTAssertThrowsError(
            try parse.parse(fromOCRText: mrz2, now: date(2026, 6, 1))
        ) { error in
            XCTAssertEqual(error as? ParsePassportIdentityError, .underage)
        }
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.calendar = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")
        c.year = y; c.month = m; c.day = d
        return c.date!
    }
}
