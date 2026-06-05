// Module: SparkCommunity — Text post draft (MODULE-E).

import Foundation

public struct CreateCommunityPostDraft: Sendable, Equatable {
    public var title: String
    public var body: String

    public init(title: String = "", body: String = "") {
        self.title = title
        self.body = body
    }

    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
