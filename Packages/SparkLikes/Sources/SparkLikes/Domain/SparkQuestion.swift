// Module: SparkLikes — Hinge-style prompt + answer on a discover profile.

import Foundation

public struct SparkQuestion: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let question: String
    public let answer: String

    public init(id: String, question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}
