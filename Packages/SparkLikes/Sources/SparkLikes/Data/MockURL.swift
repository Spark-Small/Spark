// Module: SparkLikes — Safe URL construction for mock and preview fixtures.

import Foundation

enum MockURL {
    static func require(_ string: String, file: StaticString = #file, line: UInt = #line) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid mock URL: \(string)", file: file, line: line)
        }
        return url
    }
}
