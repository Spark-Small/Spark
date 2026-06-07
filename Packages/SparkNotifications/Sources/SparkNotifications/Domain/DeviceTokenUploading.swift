// Module: SparkNotifications — APNs device token registration protocol.

import Foundation

public protocol DeviceTokenUploading: Sendable {
    func upload(apnsToken: Data) async
}
