// Module: SparkLikes — Like strength (standard vs spark / super-like).

import Foundation

public enum LikeIntensity: String, Sendable, Equatable, Codable {
    case like
    case spark

    public var wireValue: String { rawValue }
}
