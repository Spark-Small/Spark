// Module: Spark App — SwiftUI environment for search repository.

import SparkSearch
import SwiftUI

public struct SearchRepositoryBox: @unchecked Sendable {
    public let repository: any SearchRepository

    public init(_ repository: any SearchRepository) {
        self.repository = repository
    }
}

private struct SearchRepositoryEnvironmentKey: EnvironmentKey {
    static let defaultValue = SearchRepositoryBox(MockSearchRepository())
}

public extension EnvironmentValues {
    var searchRepositoryBox: SearchRepositoryBox {
        get { self[SearchRepositoryEnvironmentKey.self] }
        set { self[SearchRepositoryEnvironmentKey.self] = newValue }
    }
}
