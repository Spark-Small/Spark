// Module: SparkNotifications — No-op token upload for Mock backend.

import Foundation

public struct NoOpDeviceTokenUploader: DeviceTokenUploading, Sendable {
    public init() {}

    public func upload(apnsToken: Data) async {}
}
