// Module: SparkCore — Shared UGC text guard (client pre-check; server is source of truth).

import Foundation

public enum UGCModeration: Sendable {
  /// Keep in sync with `cloudfunctions/spark-api/lib/content-moderation.js`.
  public static let blockedTokens = [
    "违禁",
    "赌博",
    "色情",
    "刷单",
    "引流微信",
    "加微信",
    "代办证件",
  ]

  /// Returns the matched blocked token when `text` violates guidelines.
  public static func firstViolation(in text: String) -> String? {
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !normalized.isEmpty else { return nil }
    for token in blockedTokens where normalized.contains(token.lowercased()) {
      return token
    }
    return nil
  }
}
