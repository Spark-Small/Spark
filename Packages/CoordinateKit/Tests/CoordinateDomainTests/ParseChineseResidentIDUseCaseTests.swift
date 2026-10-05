import CoordinateDomain
import CoordinateModels
import XCTest

final class ParseChineseResidentIDUseCaseTests: XCTestCase {
    private let parse = ParseChineseResidentIDUseCase()

    /// 构造合法校验码的测试号（出生 1990-01-01；17 位本体 + 校验位）。
    private func makeValidID(genderOdd: Bool = true) -> String {
        // 6 行政区 + 8 出生 + 3 顺序码（末位奇男偶女）
        let partial = "11010519900101" + (genderOdd ? "013" : "012")
        precondition(partial.count == 17)
        let weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
        let map = Array("10X98765432")
        var sum = 0
        for (i, w) in weights.enumerated() {
            sum += Int(String(partial[partial.index(partial.startIndex, offsetBy: i)]))! * w
        }
        return partial + String(map[sum % 11])
    }

    func testParsesGenderAgeAndMasks() throws {
        let id = makeValidID(genderOdd: true)
        let result = try parse.parse(idNumber: id, now: date(2026, 6, 1))
        XCTAssertEqual(result.gender, .male)
        XCTAssertEqual(result.age, 36)
        XCTAssertTrue(result.idNumberMasked.hasSuffix(String(id.suffix(4))))
        XCTAssertFalse(result.idNumberFingerprint.isEmpty)
        XCTAssertEqual(result.idNumberFingerprint.count, 64)
    }

    func testRejectsBadChecksum() {
        XCTAssertThrowsError(try parse.parse(idNumber: "11010519900101333X")) { error in
            XCTAssertEqual(error as? ParseChineseResidentIDError, .checksumFailed)
        }
    }

    func testExtractsFromOCRNoise() throws {
        let id = makeValidID(genderOdd: false)
        let ocr = "姓名 测试\n公民身份号码 \(id)\n住址 上海市"
        let result = try parse.parse(fromOCRText: ocr, now: date(2026, 6, 1))
        XCTAssertEqual(result.gender, .female)
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.calendar = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")
        c.year = y; c.month = m; c.day = d
        return c.date!
    }
}
