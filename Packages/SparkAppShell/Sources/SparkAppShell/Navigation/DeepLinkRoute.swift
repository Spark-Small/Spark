// Module: SparkAppShell — Parsed deep link destinations.

import Foundation
import SparkPayments

public enum DeepLinkRoute: Equatable, Sendable {
    case tab(SparkTab, query: String?)
    case paywall(PaywallPlacement)
    case conversation(threadID: String)
    case communityPost(postID: String)
    case communityRecap(activityID: String)
    case activityDetail(activityID: String)
}
