// Module: SparkMessages — Local peer display name (remark) persistence.

import Foundation

public protocol PeerDisplayNameStoring: Sendable {
    func alias(for userID: String) -> String?
    func setAlias(_ alias: String?, for userID: String)
}
