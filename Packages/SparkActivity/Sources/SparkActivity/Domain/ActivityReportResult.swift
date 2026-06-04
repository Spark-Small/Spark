// Module: SparkActivity — Report API acknowledgment (Phase 23).

import Foundation

public struct ActivityReportResult: Sendable, Equatable {
    public let reportID: String

    public init(reportID: String) {
        self.reportID = reportID
    }
}
