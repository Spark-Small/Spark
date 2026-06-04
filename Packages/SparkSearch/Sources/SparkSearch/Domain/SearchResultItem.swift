// Module: SparkSearch — Search result row.

import Foundation

public struct SearchResultItem: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let kind: String

    public init(id: String, title: String, subtitle: String, kind: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
    }
}
