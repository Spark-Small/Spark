// Module: SparkActivity — Copy invite text to pasteboard.

import UIKit

@MainActor
enum ActivityPasteboard {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
