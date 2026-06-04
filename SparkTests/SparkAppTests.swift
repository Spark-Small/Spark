//
//  SparkAppTests.swift
//  Spark
//

import SparkCore
import Testing

struct SparkAppTests {
    @Test func appErrorDescriptionsAreLocalized() {
        #expect(AppError.unauthorized.errorDescription != nil)
    }
}
